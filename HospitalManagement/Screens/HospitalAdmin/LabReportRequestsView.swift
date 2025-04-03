//
//  LabReportRequestsView.swift
//  HospitalManagement
//
//  Created by Mariyo on 21/03/25.
//

import SwiftUI

struct LabReport: Identifiable {
    let id: UUID
    let patientName: String
    let testType: String
    let requestDate: Date
    let status: ReportStatus
    let doctorName: String
}

enum ReportStatus: String {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

struct LabReportRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var searchText = ""
    @State private var selectedFilter: ReportStatus?
    @State private var labReports: [LabReport] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentHospitalId: UUID?
    
    var filteredReports: [LabReport] {
        var reports = labReports
        
        if !searchText.isEmpty {
            reports = reports.filter { report in
                report.patientName.localizedCaseInsensitiveContains(searchText) ||
                report.testType.localizedCaseInsensitiveContains(searchText) ||
                report.doctorName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let filter = selectedFilter {
            reports = reports.filter { $0.status == filter }
        }
        
        return reports
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search reports...", text: $searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterPill(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        
                        FilterPill(title: ReportStatus.pending.rawValue,
                                 isSelected: selectedFilter == .pending,
                                 color: ReportStatus.pending.color) {
                            selectedFilter = .pending
                        }
                        
                        FilterPill(title: ReportStatus.inProgress.rawValue,
                                 isSelected: selectedFilter == .inProgress,
                                 color: ReportStatus.inProgress.color) {
                            selectedFilter = .inProgress
                        }
                        
                        FilterPill(title: ReportStatus.completed.rawValue,
                                 isSelected: selectedFilter == .completed,
                                 color: ReportStatus.completed.color) {
                            selectedFilter = .completed
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Reports List
            Group {
                if isLoading {
                    ProgressView("Loading lab reports...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error Loading Lab Tests")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button(action: {
                            Task {
                                await loadLabReports()
                            }
                        }) {
                            Text("Try Again")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredReports.isEmpty {
                    if searchText.isEmpty && selectedFilter == nil {
                        ContentUnavailableView(
                            "No Lab Reports",
                            systemImage: "cross.case.fill",
                            description: Text("There are no lab test reports yet")
                        )
                    } else {
                        ContentUnavailableView(
                            "No Matching Reports",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your search or filters")
                        )
                    }
                } else {
                    List(filteredReports) { report in
                        LabReportRow(report: report)
                            .swipeActions {
                                if report.status == .pending {
                                    Button {
                                        Task {
                                            await updateStatus(for: report.id, to: .inProgress)
                                        }
                                    } label: {
                                        Label("Start", systemImage: "play.fill")
                                    }
                                    .tint(.blue)
                                }
                                
                                if report.status == .inProgress {
                                    Button {
                                        Task {
                                            await updateStatus(for: report.id, to: .completed)
                                        }
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .navigationTitle("Lab Reports")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadLabReports()
        }
        .refreshable {
            await loadLabReports()
        }
    }
    
    private func loadLabReports() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First check if we have a hospital ID
            if let hospitalIdString = UserDefaults.standard.string(forKey: "currentHospitalId"),
               let hospitalId = UUID(uuidString: hospitalIdString) {
                print("Found hospital ID: \(hospitalId)")
                currentHospitalId = hospitalId
                
                // Fetch lab reports for this hospital
                labReports = try await supabaseController.fetchHospitalLabTests(hospitalId: hospitalId)
                print("Successfully loaded \(labReports.count) lab reports")
            } else {
                // If no hospital ID is found, try to get it from the admin profile
                print("No hospital ID found in UserDefaults, attempting to fetch from admin profile...")
                if let (admin, hospital) = try await supabaseController.fetchAdminProfile() {
                    currentHospitalId = hospital.id
                    UserDefaults.standard.set(hospital.id.uuidString, forKey: "currentHospitalId")
                    print("Retrieved and stored hospital ID: \(hospital.id)")
                    
                    // Now fetch lab reports with the retrieved hospital ID
                    labReports = try await supabaseController.fetchHospitalLabTests(hospitalId: hospital.id)
                    print("Successfully loaded \(labReports.count) lab reports")
                } else {
                    errorMessage = "Could not determine hospital ID. Please ensure you're logged in as a hospital admin."
                }
            }
        } catch {
            print("Error loading lab reports: \(error)")
            errorMessage = "Failed to load lab reports: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func updateStatus(for testId: UUID, to status: ReportStatus) async {
        do {
            // Convert ReportStatus to LabTest.TestStatus
            let labTestStatus: LabTest.TestStatus
            switch status {
            case .completed:
                labTestStatus = .completed
            case .inProgress, .pending:
                labTestStatus = .pending
            }
            
            try await supabaseController.updateLabTestStatus(testId: testId, status: labTestStatus)
            await loadLabReports() // Refresh the list
        } catch {
            errorMessage = "Failed to update status: \(error.localizedDescription)"
        }
    }
}

struct AdminLabTestValueView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseController()
    let testId: UUID
    let testType: String
    
    @State private var testValue: String = ""
    @State private var testComponents: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Test Details")) {
                    Text("Test Type: \(testType)")
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Test Results")) {
                    TextField("Test Value", text: $testValue)
                        .keyboardType(.decimalPad)
                    
                    TextField("Test Components (comma separated)", text: $testComponents)
                        .textInputAutocapitalization(.never)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: submitResults) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Submit Results")
                        }
                    }
                    .disabled(isSubmitting || testValue.isEmpty)
                }
            }
            .navigationTitle("Add Test Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Test results have been successfully submitted.")
            }
        }
    }
    
    private func submitResults() {
        guard let value = Double(testValue) else {
            errorMessage = "Please enter a valid numeric value"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let components = testComponents
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }
        
        Task {
            do {
                try await supabaseController.updateLabTestValue(
                    testId: testId,
                    testValue: value,
                    testComponents: components.isEmpty ? nil : components
                )
                showSuccessAlert = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

struct LabReportRow: View {
    let report: LabReport
    @State private var showingTestValueInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(report.patientName)
                    .font(.headline)
                Spacer()
                LabReportStatusBadge(status: report.status)
            }
            
            Text(report.testType)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(report.requestDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())  // Make entire row tappable
        .onTapGesture {
            if report.status != .completed {
                showingTestValueInput = true
            }
        }
        .sheet(isPresented: $showingTestValueInput) {
            AdminLabTestValueView(testId: report.id, testType: report.testType)
        }
        // Visual feedback that completed tests are not interactive
        .opacity(report.status == .completed ? 0.8 : 1.0)
    }
}

struct LabReportStatusBadge: View {
    let status: ReportStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color)
            .cornerRadius(12)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct EmptyReportsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.mint)
            
            if searchText.isEmpty {
                Text("No Lab Reports")
                    .font(.headline)
                Text("Lab report requests will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No Matching Reports")
                    .font(.headline)
                Text("Try adjusting your search")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
}

#Preview {
    NavigationStack {
        LabReportRequestsView()
            .environmentObject(HospitalManagementViewModel())
    }
} 
