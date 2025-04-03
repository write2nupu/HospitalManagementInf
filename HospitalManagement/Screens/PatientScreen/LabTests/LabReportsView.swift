import SwiftUI

// New struct to handle the simplified lab test data
struct SimplifiedLabTest: Identifiable {
    let id = UUID()
    let testName: String
    let testDate: Date
    let status: String
    let doctorName: String?
    let diagnosis: String?
    
    var statusEnum: TestStatus {
        TestStatus(rawValue: status) ?? .pending
    }
    
    enum TestStatus: String {
        case pending = "Pending"
        case completed = "Completed"
    }
}

struct LabReportsView: View {
    @StateObject private var supabase = SupabaseController()
    @State private var labTests: [(id: UUID, testName: String, testDate: Date, status: String, doctorName: String?, diagnosis: String?)] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    @State private var selectedTest: (id: UUID, testName: String, testDate: Date, status: String, doctorName: String?, diagnosis: String?)?
    @State private var showingTestDetail = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                } else if labTests.isEmpty {
                    Text("No lab tests found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(labTests, id: \.id) { test in
                        LabTestCard(
                            testName: test.testName,
                            testDate: test.testDate,
                            status: test.status,
                            doctorName: test.doctorName,
                            diagnosis: test.diagnosis
                        )
                        .onTapGesture {
                            selectedTest = test
                            showingTestDetail = true
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Lab Reports")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTestDetail) {
            if let test = selectedTest {
                LabTestDetailView(test: (testName: test.testName, 
                                      testDate: test.testDate, 
                                      status: test.status, 
                                      doctorName: test.doctorName,
                                      diagnosis: test.diagnosis))
            }
        }
        .onAppear {
            Task {
                await fetchLabTests()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error?.localizedDescription ?? "Unknown error occurred")
        }
    }
    
    private func fetchLabTests() async {
        do {
            if let patientId = UUID(uuidString: UserDefaults.standard.string(forKey: "currentPatientId") ?? "") {
                print("Fetching lab tests for patient: \(patientId)")
                let tests = try await supabase.fetchLabTests(patientId: patientId)
                await MainActor.run {
                    self.labTests = tests
                    self.isLoading = false
                }
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid patient ID"])
            }
        } catch {
            print("Error loading lab tests: \(error)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
                self.showError = true
            }
        }
    }
}

struct LabTestCard: View {
    let testName: String
    let testDate: Date
    let status: String
    let doctorName: String?
    let diagnosis: String?
    
    private var testArray: [String] {
        testName.components(separatedBy: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Doctor and Status Header
            HStack(alignment: .center) {
                if let doctorName = doctorName {
                    Label {
                        Text(doctorName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.mint)
                    }
                }
                
                Spacer()
                
                LabTestStatusBadge(status: status)
            }
            
            // Date
            Label {
                Text(testDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: "calendar")
                    .foregroundColor(.mint)
            }
            
            // Tests List
            VStack(alignment: .leading, spacing: 8) {
                Text("Tests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(testArray, id: \.self) { test in
                    Label {
                        Text(test)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.mint)
                    }
                }
            }
            
            // Diagnosis if available
            if let diagnosis = diagnosis {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Diagnosis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(diagnosis)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct LabTestStatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "pending":
            return .orange
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
}

struct LabTestDetailView: View {
    let test: (testName: String, testDate: Date, status: String, doctorName: String?, diagnosis: String?)
    
    private var testArray: [String] {
        test.testName.components(separatedBy: ", ")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Status Badge
                HStack {
                    Spacer()
                    LabTestStatusBadge(status: test.status)
                }
                
                // Doctor Info
                if let doctorName = test.doctorName {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Referred by")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Label {
                            Text(doctorName)
                                .font(.headline)
                        } icon: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.mint)
                        }
                    }
                }
                
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Label {
                        Text(test.testDate.formatted(date: .long, time: .omitted))
                            .font(.headline)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.mint)
                    }
                }
                
                // Tests
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tests Included")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(testArray, id: \.self) { test in
                        Label {
                            Text(test)
                                .font(.body)
                        } icon: {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.mint)
                        }
                    }
                }
                
                // Diagnosis
                if let diagnosis = test.diagnosis {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diagnosis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(diagnosis)
                            .font(.body)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Test Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationView {
        LabReportsView()
    }
} 
