import SwiftUI

struct LeaveApplicationView: View {
    
    var Doctor: Doctor
    @StateObject private var supabase = SupabaseController()
    
    let leaveTypes: [LeaveType] = [
        .sickLeave, .casualLeave, .annualLeave,
        .emergencyLeave, .maternityPaternityLeave, .conferenceLeave
    ]
    
    @State private var selectedLeaveType: LeaveType? = nil
    @State private var reason = ""
    @State private var leaveDays: Int = 1
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var pendingLeave: Leave? = nil
    @State private var isLeaveApproved = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Form {
                        if let leave = pendingLeave {
                            leaveStatusSection(leave)
                        } else {
                            Section(header: Text("Leave Type")) {
                                Picker("Select Leave Type", selection: $selectedLeaveType) {
                                    Text("Select Leave Type").tag(Optional<LeaveType>(nil))
                                    ForEach(leaveTypes, id: \.self) { leave in
                                        Text(leave.displayName).tag(Optional(leave))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Section(header: Text("Reason for Leave")) {
                                TextField("Enter reason...", text: $reason)
                            }
                            
                            Section(header: Text("Leave Duration")) {
                                Text("Number days: \(leaveDays)")
                                
                                DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                                    .onChange(of: startDate) { updateLeaveDays() }
                                
                                DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .onChange(of: endDate) { updateLeaveDays() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Apply For Leave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        Task {
                            await applyForLeave()
                        }
                    }
                    .disabled(pendingLeave != nil || isLoading)
                    .foregroundColor(AppConfig.buttonColor)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Leave application submitted successfully")
            }
            .task {
                await loadPendingLeave()
            }
        }
    }
    
    // MARK: - Leave Status View
    @ViewBuilder
    private func leaveStatusSection(_ leave: Leave) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: leave.status == .approved ? "checkmark.circle.fill" : 
                      leave.status == .rejected ? "xmark.circle.fill" : "clock.fill")
                    .foregroundColor(leave.status == .approved ? .green : 
                                   leave.status == .rejected ? .red : .yellow)
                
                Text(leave.status.rawValue + " Leave")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("🗂 Type:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(leave.type.displayName)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("📝 Reason:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(leave.reason)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            HStack {
                Text("📅 Duration:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("\(leave.startDate.formatted()) → \(leave.endDate.formatted())")
                    .fontWeight(.semibold)
            }
            
            switch leave.status {
            case .approved:
                Text("Your leave has been approved.")
                    .font(.footnote)
                    .foregroundColor(.green)
                    .padding(.top, 5)
            case .rejected:
                Text("Your leave application was rejected.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            case .pending:
                Text("Leave is pending approval from Admin.")
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 3)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    private func updateLeaveDays() {
        if let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day {
            leaveDays = max(1, days + 1) // Include both start and end days
        }
    }
    
    private func applyForLeave() async {
        guard let selectedLeaveType = selectedLeaveType else {
            showError("Please select a leave type.")
            return
        }
        guard !reason.isEmpty else {
            showError("Please enter a reason for your leave.")
            return
        }
        guard leaveDays > 0 else {
            showError("Invalid leave duration.")
            return
        }
        guard startDate <= endDate else {
            showError("Start date must be before or equal to end date.")
            return
        }
        
        isLoading = true
        //    let id: UUID
        //    let doctorId: UUID
        //    let hospitalId: UUID
        //    var type: LeaveType
        //    let reason: String
        //    let startDate: Date
        //    let endDate: Date
        //    var status: LeaveStatus
        
//        let id: UUID
//        let doctorId: UUID
//        let hospitalId: UUID
//        let type: LeaveType
//        let reason: String
//        let startDate: Date
//        let endDate: Date
//        var status: LeaveStatus
//        
        do {
            let newLeave = Leave(
                id: UUID(),
                doctorId: Doctor.id,
                hospitalId: Doctor.hospital_id ?? UUID(),
                type: selectedLeaveType,
                reason: reason,
                startDate: startDate,
                endDate: endDate,
                status: .pending
            )
            
            try await supabase.applyForLeave(newLeave)
            pendingLeave = newLeave
            showSuccess = true
            
        } catch {
            showError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func loadPendingLeave() async {
        isLoading = true
        do {
            pendingLeave = try await supabase.fetchPendingLeave(doctorId: Doctor.id)
        } catch {
            showError(error.localizedDescription)
        }
        isLoading = false
    }
}

// MARK: - Leave Data Model
//struct Leave {
//    let id: UUID
//    let doctorId: UUID
//    let hospitalId: UUID
//    var type: LeaveType
//    let reason: String
//    let startDate: Date
//    let endDate: Date
//    var status: LeaveStatus
//}
//
//// MARK: - Leave Status Enum
//enum LeaveStatus: String {
//    case pending = "Pending"
//    case approved = "Approved"
//    case rejected = "Rejected"
//}
//
//// MARK: - Leave Types Enum
//enum LeaveType: String, CaseIterable, Identifiable {
//    case sickLeave = "Sick Leave"
//    case casualLeave = "Casual Leave"
//    case annualLeave = "Annual Leave"
//    case emergencyLeave = "Emergency Leave"
//    case maternityPaternityLeave = "Maternity/Paternity Leave"
//    case conferenceLeave = "Conference Leave"
//    
//    var id: String { self.rawValue }
//    var displayName: String { self.rawValue }
//}

