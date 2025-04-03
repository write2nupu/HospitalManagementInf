//
//  DoctorLeaveView.swift
//  HospitalManagement
//
//  Created by sudhanshu on 01/04/25.
//

import SwiftUI

struct DoctorLeaveView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var leaveDetails: [(leave: Leave, doctor: Doctor, department: Department?)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: LeaveStatus?
    @State private var showingFilterSheet = false
    @AppStorage("hospitalId") private var hospitalIdString: String?
    
    var filteredLeaves: [(leave: Leave, doctor: Doctor, department: Department?)] {
        if let filter = selectedFilter {
            return leaveDetails.filter { $0.leave.status == filter }
        }
        return leaveDetails
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if filteredLeaves.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No leave requests found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(selectedFilter == nil ? 
                        "When doctors request leave, they will appear here" :
                        "No \(selectedFilter?.rawValue.lowercased() ?? "") leave requests found")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredLeaves, id: \.leave.id) { leaveDetail in
                    ZStack {
                        NavigationLink(destination: LeaveRequestDetailView(leaveDetail: leaveDetail) { updatedLeave in
                            // Update the leave request in the list
                            if let index = leaveDetails.firstIndex(where: { $0.leave.id == updatedLeave.id }) {
                                leaveDetails[index].leave = updatedLeave
                            }
                        }) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        LeaveRequestCard(leaveDetail: leaveDetail)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Leave Requests")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        selectedFilter = nil
                    } label: {
                        Label("All Requests", systemImage: "list.bullet")
                    }
                    
                    Button {
                        selectedFilter = .pending
                    } label: {
                        Label("Pending", systemImage: "clock")
                    }
                    
                    Button {
                        selectedFilter = .approved
                    } label: {
                        Label("Approved", systemImage: "checkmark.circle")
                    }
                    
                    Button {
                        selectedFilter = .rejected
                    } label: {
                        Label("Rejected", systemImage: "xmark.circle")
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .onAppear {
            Task {
                await loadLeaveRequests()
            }
        }
        .refreshable {
            await loadLeaveRequests()
        }
    }
    
    private func loadLeaveRequests() async {
        guard let hospitalIdString = hospitalIdString,
              let hospitalId = UUID(uuidString: hospitalIdString) else {
            errorMessage = "Hospital ID not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            leaveDetails = try await supabaseController.fetchLeaveRequests(hospitalId: hospitalId)
        } catch {
            errorMessage = "Failed to load leave requests: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct LeaveRequestCard: View {
    let leaveDetail: (leave: Leave, doctor: Doctor, department: Department?)
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                // Doctor Info
                HStack(alignment: .center, spacing: 12) {
                    // Doctor Profile Image
                    ZStack {
                        Circle()
                            .fill(Color.mint.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.mint)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dr. \(leaveDetail.doctor.full_name)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(leaveDetail.department?.name ?? "No Department")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge3(status: leaveDetail.leave.status)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Leave Details
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.mint)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Leave Period")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(formatDate(leaveDetail.leave.startDate)) - \(formatDate(leaveDetail.leave.endDate))")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.mint)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reason")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(leaveDetail.leave.reason)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
                .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .contentShape(Rectangle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatusBadge3: View {
    let status: LeaveStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch status {
        case .pending:
            return "clock.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

#Preview {
    NavigationView {
        DoctorLeaveView()
    }
}

