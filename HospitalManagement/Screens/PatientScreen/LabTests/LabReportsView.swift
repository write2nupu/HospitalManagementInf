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
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTest: (id: UUID, testName: String, testDate: Date, status: String, doctorName: String?, diagnosis: String?)?
    @State private var showingDetail = false
    @State private var searchText = ""
    @State private var selectedFilters: Set<LabTest.LabTestName> = []  // Changed to Set for multiple selection
    @State private var showingFilterSheet = false
    
    private var filteredTests: [(id: UUID, testName: String, testDate: Date, status: String, doctorName: String?, diagnosis: String?)] {
        var filtered = labTests
        
        // Apply test type filters if any are selected
        if !selectedFilters.isEmpty {
            filtered = filtered.filter { test in
                // Split the test names and check if any match the selected filters
                let testNames = test.testName.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                return selectedFilters.contains { filter in
                    testNames.contains(filter.rawValue)
                }
            }
        }
        
        // Then apply search text
        if !searchText.isEmpty {
            let searchTerms = searchText.lowercased().split(separator: " ")
            
            filtered = filtered.filter { test in
                let testName = test.testName.lowercased()
                let doctorName = test.doctorName?.lowercased() ?? ""
                let status = test.status.lowercased()
                let dateString = formatSearchDate(test.testDate)
                
                return searchTerms.allSatisfy { term in
                    testName.contains(term) ||
                    doctorName.contains(term) ||
                    status.contains(term) ||
                    dateString.contains(term)
                }
            }
        }
        
        // Sort by date, most recent first
        return filtered.sorted { $0.testDate > $1.testDate }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar at the top
            searchBar
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color(.systemBackground))
            
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Error Loading Lab Tests",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if filteredTests.isEmpty {
                    if !searchText.isEmpty {
                        ContentUnavailableView(
                            "No Matching Tests",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your search terms")
                        )
                    } else {
                        ContentUnavailableView(
                            "No Lab Tests",
                            systemImage: "cross.case.fill",
                            description: Text("You don't have any lab tests yet")
                        )
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTests, id: \.id) { test in
                                LabTestCard(
                                    id: test.id,
                                    testName: test.testName,
                                    testDate: test.testDate,
                                    status: test.status,
                                    doctorName: test.doctorName,
                                    diagnosis: test.diagnosis
                                )
                                .onTapGesture {
                                    selectedTest = test
                                    showingDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Lab Reports")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDetail) {
            if let test = selectedTest {
                LabTestDetailView(
                    id: test.id,
                    testName: test.testName,
                    testDate: test.testDate,
                    status: test.status,
                    doctorName: test.doctorName,
                    diagnosis: test.diagnosis
                )
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            filterSheet
        }
        .onAppear {
            Task {
                await loadLabTests()
            }
        }
    }
    
    private func loadLabTests() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
               let patientId = UUID(uuidString: patientIdString) {
                labTests = try await supabase.fetchLabTests(patientId: patientId)
            } else {
                errorMessage = "Patient ID not found"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search tests, doctors, status...", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            filterButton
        }
        .padding(.horizontal)
    }
    
    var filterSheet: some View {
        NavigationView {
            List {
                ForEach(LabTest.LabTestName.allCases, id: \.self) { testType in
                    Button(action: {
                        if selectedFilters.contains(testType) {
                            selectedFilters.remove(testType)
                        } else {
                            selectedFilters.insert(testType)
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Icon for the test type
                            Image(systemName: testType.icon)
                                .foregroundColor(.mint)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(testType.rawValue)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Checkmark for selected items
                            if selectedFilters.contains(testType) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.mint)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Filter by Test Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingFilterSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        selectedFilters.removeAll()
                    }
                    .disabled(selectedFilters.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // Update the filter button to show selected test count
    private var filterButton: some View {
        Button(action: {
            showingFilterSheet = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundColor(selectedFilters.isEmpty ? .mint : .white)
                if !selectedFilters.isEmpty {
                    Text("\(selectedFilters.count)")
                        .font(.caption)
                        .padding(4)
                        .background(Color.white)
                        .clipShape(Circle())
                        .foregroundColor(.mint)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(selectedFilters.isEmpty ? Color.clear : Color.mint)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.mint, lineWidth: selectedFilters.isEmpty ? 1 : 0)
            )
        }
    }
    
    // Helper function to format date for searching
    private func formatSearchDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date).lowercased()
    }
}

struct LabTestCard: View {
    let id: UUID
    let testName: String
    let testDate: Date
    let status: String
    let doctorName: String?
    let diagnosis: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Doctor Info
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.mint)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let doctor = doctorName {
                        Text("Dr. \(doctor)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Text(testDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                LabTestStatusBadge(status: status)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Tests Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Tests")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                let tests = testName.split(separator: ",").map(String.init)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tests, id: \.self) { test in
                        HStack(spacing: 12) {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.mint)
                                .font(.system(size: 14))
                            
                            Text(test.trimmingCharacters(in: .whitespaces))
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
            
            // Diagnosis Section if available
            if let diagnosis = diagnosis, !diagnosis.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diagnosis")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(diagnosis)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct LabTestDetailView: View {
    let id: UUID
    let testName: String
    let testDate: Date
    let status: String
    let doctorName: String?
    let diagnosis: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Doctor Info
                    if let doctor = doctorName {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.mint)
                            Text("Dr. \(doctor)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Status Badge
                    LabTestStatusBadge(status: status)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.mint)
                        Text(testDate.formatted(date: .long, time: .omitted))
                            .font(.headline)
                    }
                    
                    // Tests
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tests Included")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        let tests = testName.split(separator: ",").map(String.init)
                        ForEach(tests, id: \.self) { test in
                            HStack {
                                Image(systemName: "cross.case.fill")
                                    .foregroundColor(.mint)
                                Text(test.trimmingCharacters(in: .whitespaces))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Diagnosis if available
                    if let diagnosis = diagnosis, !diagnosis.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Diagnosis")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Text(diagnosis)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Lab Test Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LabTestStatusBadge: View {
    let status: String
    
    private var statusColor: Color {
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
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(6)
    }
}

// Helper extension to get icon for lab test type
extension LabTest.LabTestName {
    var icon: String {
        switch self {
        case .completeBloodCount, .bloodSugarTest, .bloodCulture:
            return "drop.fill"
        case .urineAnalysis, .urineCulture:
            return "flask.fill"
        case .thyroidFunctionTest, .liverFunctionTest, .kidneyFunctionTest:
            return "waveform.path.ecg"
        case .vitaminDTest, .vitaminB12Test, .calciumTest:
            return "pill.fill"
        case .lipidProfile:
            return "heart.fill"
        case .cReactiveProtein, .erythrocyteSedimentationRate:
            return "cross.case.fill"
        case .hba1c, .fastingBloodSugar, .postprandialBloodSugar:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

#Preview {
    NavigationView {
        LabReportsView()
    }
} 
