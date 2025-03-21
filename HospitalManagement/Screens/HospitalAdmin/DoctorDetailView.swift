import SwiftUI

struct DoctorDetailView: View {
    let doctor: Doctor
    @StateObject private var supabaseController = SupabaseController()
    @State private var showStatusConfirmation = false
    @State private var showStatusChangeAlert = false
    @State private var departmentName: String = ""
    
    var body: some View {
        List {
            Section("Personal Information") {
                InfoRow(title: "Doctor's Name", value: doctor.fullName, icon: "person.fill", color: .blue)
                InfoRow(title: "Department", value: departmentName, icon: "stethoscope", color: .pink)
                InfoRow(title: "License Number", value: doctor.licenseNumber, icon: "creditcard.fill", color: .indigo)
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(doctor.isActive ? "Active" : "Inactive")
                                .font(.body)
                        }
                    } icon: {
                        Image(systemName: doctor.isActive ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(doctor.isActive ? .green : .red)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { doctor.isActive },
                        set: { _ in showStatusConfirmation = true }
                    ))
                    .labelsHidden()
                }
            }
            
            Section("Contact Information") {
                InfoRow(title: "Phone", value: doctor.phoneNumber, icon: "phone.fill", color: .green)
                    .textContentType(.telephoneNumber)
                InfoRow(title: "Email", value: doctor.email, icon: "envelope.fill", color: .orange)
                    .textContentType(.emailAddress)
            }
            
            Section("Professional Information") {
                InfoRow(title: "Experience", value: "\(doctor.experience) years", icon: "clock.fill", color: .purple)
                InfoRow(title: "Qualifications", value: doctor.qualifications, icon: "book.fill", color: .brown)
            }
        }
        .alert(doctor.isActive ? "Confirm Deactivation" : "Confirm Activation", 
               isPresented: $showStatusConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(doctor.isActive ? "Deactivate" : "Activate", 
                  role: doctor.isActive ? .destructive : .none) {
                Task {
                    await toggleDoctorStatus()
                }
            }
        } message: {
            Text(doctor.isActive ? 
                "Are you sure you want to deactivate Dr. \(doctor.fullName)?" :
                "Do you want to activate Dr. \(doctor.fullName)?")
        }
        .alert("Status Updated", isPresented: $showStatusChangeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(doctor.fullName) has been \(doctor.isActive ? "deactivated" : "activated")")
        }
        .task {
            if let departmentId = doctor.departmentId {
                if let department = await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
                    departmentName = department.name
                }
            }
        }
    }
    
    private func toggleDoctorStatus() async {
        var updatedDoctor = doctor
        updatedDoctor.isActive.toggle()
        
        do {
            try await supabaseController.client
                .from("Doctors")
                .update(updatedDoctor)
                .eq("id", value: updatedDoctor.id)
                .execute()
            
            showStatusChangeAlert = true
        } catch {
            print("Error updating doctor status: \(error)")
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.body)
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, 2)
    }
}

struct StatusBadge1: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isActive ? "Active" : "Inactive")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}


