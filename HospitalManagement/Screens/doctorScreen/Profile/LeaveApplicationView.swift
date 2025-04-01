import SwiftUI

struct LeaveApplicationView: View {
    let leaveTypes = [
        "Sick Leave", "Casual Leave", "Annual Leave",
        "Emergency Leave", "Maternity/Paternity Leave", "Conference Leave"
    ]
    
    @State private var selectedLeaveType: String? = nil
    @State private var reason = ""
    @State private var leaveDays: Int? = 1
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var pendingLeave: Leave? = nil
    @State private var isLeaveApproved = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack {
                if let leave = pendingLeave {
                    leaveStatusSection(leave)
                } else {
                    Form {
                        Section(header: Text("Leave Type")) {
                            Picker("Select Leave Type", selection: $selectedLeaveType) {
                                Text("Select Leave Type").tag(Optional<String>(nil))
                                ForEach(leaveTypes, id: \.self) { leave in
                                    Text(leave).tag(Optional(leave))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Section(header: Text("Reason for Leave")) {
                            TextField("Enter reason...", text: $reason)
                        }
                        
                        Section(header: Text("Leave Duration")) {
                            HStack {
                                Stepper(value: Binding(
                                    get: { leaveDays ?? 1 },
                                    set: { newValue in
                                        leaveDays = newValue
                                        endDate = Calendar.current.date(byAdding: .day, value: newValue, to: startDate) ?? startDate
                                    }),
                                    in: 1...30
                                ) {
                                    Text("Days: \(leaveDays ?? 1)")
                                }
                            }
                            
                            DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                                .onChange(of: startDate) {  updateLeaveDays() }
                            
                            DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .onChange(of: endDate) { updateLeaveDays() }
                        }
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Apply For Leave").font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyForLeave()
                    }
                    .disabled(pendingLeave != nil)
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadPendingLeave()
            }
        }
    }
    
    @ViewBuilder
    private func leaveStatusSection(_ leave: Leave) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isLeaveApproved ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundColor(isLeaveApproved ? .green : .yellow)
                
                Text(isLeaveApproved ? "Approved Leave" : "Pending Leave")
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
                Text(leave.type)
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
            
            if isLeaveApproved {
                Text("Your leave has been approved.")
                    .font(.footnote)
                    .foregroundColor(.green)
                    .padding(.top, 5)
            } else {
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
    
    private func updateLeaveDays() {
        if let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day {
            leaveDays = max(1, days)
        }
    }
    
    private func applyForLeave() {
        guard let selectedLeaveType = selectedLeaveType else {
            showError("Please select a leave type.")
            return
        }
        guard !reason.isEmpty else {
            showError("Please enter a reason for your leave.")
            return
        }
        guard let leaveDays = leaveDays, leaveDays > 0 else {
            showError("Invalid leave duration.")
            return
        }
        guard startDate <= endDate else {
            showError("Start date must be before or equal to end date.")
            return
        }
        
        pendingLeave = Leave(type: selectedLeaveType, reason: reason, startDate: startDate, endDate: endDate, status: .pending)
        isLeaveApproved = false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func loadPendingLeave() {
        pendingLeave = nil
    }
}

struct Leave {
    var type: String
    var reason: String
    var startDate: Date
    var endDate: Date
    var status: LeaveStatus
}

enum LeaveStatus {
    case pending
    case approved
    case rejected
}

#Preview {
    LeaveApplicationView()
}
