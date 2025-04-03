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
    @State private var labReports: [LabReport] = [] // This will be populated from your database
    
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
            if filteredReports.isEmpty {
                EmptyReportsView(searchText: searchText)
            } else {
                List(filteredReports) { report in
                    LabReportRow(report: report)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Lab Reports")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // TODO: Fetch lab reports from database
            await loadLabReports()
        }
    }
    
    private func loadLabReports() async {
        // TODO: Implement actual data fetching
        // This is sample data - replace with actual database calls
        labReports = [
            LabReport(id: UUID(), patientName: "John Doe", testType: "Blood Test",
                     requestDate: Date(), status: .pending, doctorName: "Dr. Smith"),
            LabReport(id: UUID(), patientName: "Jane Smith", testType: "X-Ray",
                     requestDate: Date(), status: .inProgress, doctorName: "Dr. Johnson"),
            LabReport(id: UUID(), patientName: "Mike Wilson", testType: "MRI Scan",
                     requestDate: Date(), status: .completed, doctorName: "Dr. Brown")
        ]
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = .mint
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct LabReportRow: View {
    let report: LabReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(report.patientName)
                    .font(.headline)
                Spacer()
                LabReportRequestStatusBadge(status: report.status)
            }
            
            HStack {
                Label(report.testType, systemImage: "flask")
                Spacer()
                Text(report.doctorName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(report.requestDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct LabReportRequestStatusBadge: View {
    let status: ReportStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.1))
            .foregroundColor(status.color)
            .cornerRadius(8)
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
