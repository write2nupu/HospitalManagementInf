import SwiftUI

// New struct to handle the simplified lab test data
struct SimplifiedLabTest: Identifiable {
    let id = UUID()
    let testName: String
    let testDate: Date
    let status: String
    let doctorName: String?
    
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
    @State private var labTests: [(id: UUID, testName: String, testDate: Date, status: String, doctorName: String?)] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    @State private var selectedTest: (id: UUID, testName: String, testDate: Date, status: String, doctorName: String?)?
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
                            doctorName: test.doctorName
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
                                      doctorName: test.doctorName))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(testName)
                    .font(.headline)
                Spacer()
                LabTestStatusBadge(status: status)
            }
            
            HStack {
                Label {
                    Text(testDate.formatted(.dateTime.day().month().year().hour().minute()))
                } icon: {
                    Image(systemName: "calendar")
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                if let doctorName = doctorName {
                    Label {
                        Text(doctorName)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "person")
                    }
                    .foregroundColor(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
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
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
}

struct LabTestDetailView: View {
    let test: (testName: String, testDate: Date, status: String, doctorName: String?)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Test Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(test.testName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    // Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        LabTestStatusBadge(status: test.status)
                    }
                    
                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(test.testDate.formatted(.dateTime.month().day().year().hour().minute()))
                            .font(.body)
                    }
                    
                    // Doctor
                    if let doctorName = test.doctorName {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Referred by")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(doctorName)
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Test Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationView {
        LabReportsView()
    }
} 
