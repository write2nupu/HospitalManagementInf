import SwiftUI

struct LeaveRequestDetailView: View {
    let leave: Leave
    let doctor: Doctor
    let department: Department?
    let onStatusUpdate: (Leave) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseController()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedAction: LeaveAction?
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    @State private var isAnimating = false
    @State private var affectedAppointments = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(leaveDetail: (leave: Leave, doctor: Doctor, department: Department?), onStatusUpdate: @escaping (Leave) -> Void) {
        self.leave = leaveDetail.leave
        self.doctor = leaveDetail.doctor
        self.department = leaveDetail.department
        self.onStatusUpdate = onStatusUpdate
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Doctor Profile Section
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Dr. \(doctor.full_name)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(department?.name ?? "No Department")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        StatusBadge3(status: leave.status)
                            .padding(.top, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Contact Information Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Contact Information")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow2(icon: "envelope", title: "Email", value: doctor.email_address)
                            DetailRow2(icon: "phone", title: "Phone", value: doctor.phone_num)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Leave Details Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Leave Details")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow2(icon: "calendar", title: "Leave Type", value: leave.type.rawValue)
                            DetailRow2(icon: "calendar.badge.clock", title: "Duration", value: "\(formatDate(leave.startDate)) - \(formatDate(leave.endDate))")
                            DetailRow2(icon: "text.bubble", title: "Reason", value: leave.reason)
                            
                            // Affected Appointments Card
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.mint)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Affected Appointments")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else if let error = errorMessage {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else {
                                        Text("\(affectedAppointments) appointments")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Action Buttons
                    if leave.status == .pending {
                        VStack(spacing: 12) {
                            Button {
                                selectedAction = .approve
                                alertMessage = "Are you sure you want to approve this leave request? This will affect \(affectedAppointments) appointments."
                                showAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Approve Leave Request")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                                .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            
                            Button {
                                selectedAction = .reject
                                alertMessage = "Are you sure you want to reject this leave request?"
                                showAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Reject Leave Request")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Leave Request")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .alert("Leave Request Action", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) {
                    selectedAction = nil
                }
                Button("Confirm") {
                    handleLeaveAction()
                }
            } message: {
                Text(alertMessage)
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
            .onAppear {
                Task {
                    await loadAffectedAppointments()
                }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func loadAffectedAppointments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            affectedAppointments = try await supabaseController.getAffectedAppointments(
                doctorId: leave.doctorId,
                startDate: leave.startDate,
                endDate: leave.endDate
            )
        } catch {
            errorMessage = "Failed to load affected appointments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func handleLeaveAction() {
        guard let action = selectedAction else { return }
        
        Task {
            do {
                let newStatus: LeaveStatus = action == .approve ? .approved : .rejected
                try await supabaseController.updateLeaveStatus(leaveId: leave.id, status: newStatus)
                
                // If leave is approved, cancel all affected appointments
                if action == .approve {
                    try await supabaseController.cancelAppointmentsDuringLeave(
                        doctorId: leave.doctorId,
                        startDate: leave.startDate,
                        endDate: leave.endDate
                    )
                }
                
                var updatedLeave = leave
                updatedLeave.status = newStatus
                onStatusUpdate(updatedLeave)
                
                successMessage = action == .approve ?
                    "Leave request has been approved successfully. \(affectedAppointments) appointments have been cancelled." :
                    "Leave request has been rejected successfully."
                
                showSuccessAlert = true
            } catch {
                errorMessage = "Failed to \(action == .approve ? "approve" : "reject") leave request: \(error.localizedDescription)"
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct DetailRow2: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.mint)
                .frame(width: 24)
                .symbolEffect(.bounce, options: .repeating, value: true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mint.opacity(0.1))
        .cornerRadius(12)
    }
}

enum LeaveAction {
    case approve
    case reject
}

//#Preview {
//    LeaveRequestDetailView(
//        leave: Leave(
//            id: UUID(),
//            doctorId: UUID(),
//            hospitalId: UUID(),
//            type: .sickLeave,
//            reason: "Fever and flu",
//            startDate: Date(),
//            endDate: Date().addingTimeInterval(86400),
//            status: .pending
//        )
//    ) { _ in }
//}
