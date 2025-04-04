import SwiftUI

struct DoctorDetailView: View {
    @State private var doctor: Doctor
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var supabaseController = SupabaseController()
    @State private var showStatusConfirmation = false
    @State private var showStatusChangeAlert = false
    @State private var departmentName: String = ""
    @State private var isUpdating = false
    @State private var errorMessage: String? = nil
    
    init(doctor: Doctor) {
        _doctor = State(initialValue: doctor)
    }
    
    var body: some View {
        List {
            Section("Personal Information") {
                InfoRow(title: "Doctor's Name", value: doctor.full_name, icon: "person.fill", color: .blue)
                InfoRow(title: "Department", value: departmentName, icon: "stethoscope", color: .pink)
                InfoRow(title: "License Number", value: doctor.license_num, icon: "creditcard.fill", color: .indigo)
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(doctor.is_active ? "Active" : "Inactive")
                                .font(.body)
                        }
                    } icon: {
                        Image(systemName: doctor.is_active ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(doctor.is_active ? .green : .red)
                    }
                    
                    Spacer()
                    
                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Toggle("", isOn: Binding(
                            get: { doctor.is_active },
                            set: { _ in showStatusConfirmation = true }
                        ))
                        .labelsHidden()
                    }
                }
                
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Contact Information") {
                InfoRow(title: "Phone", value: doctor.phone_num, icon: "phone.fill", color: .green)
                    .textContentType(.telephoneNumber)
                InfoRow(title: "Email", value: doctor.email_address, icon: "envelope.fill", color: .orange)
                    .textContentType(.emailAddress)
            }
            
            Section("Professional Information") {
                InfoRow(title: "Experience", value: "\(doctor.experience) years", icon: "clock.fill", color: .purple)
                InfoRow(title: "Qualifications", value: doctor.qualifications, icon: "book.fill", color: .brown)
            }
        }
        .alert(doctor.is_active ? "Confirm Deactivation" : "Confirm Activation", 
               isPresented: $showStatusConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(doctor.is_active ? "Deactivate" : "Activate", 
                  role: doctor.is_active ? .destructive : .none) {
                Task {
                    await toggleDoctorStatus()
                }
            }
        } message: {
            Text(doctor.is_active ? 
                "Are you sure you want to deactivate Dr. \(doctor.full_name)?" :
                "Do you want to activate Dr. \(doctor.full_name)?")
        }
        .alert("Status Updated", isPresented: $showStatusChangeAlert) {
            Button("OK", role: .cancel) { 
                // Dismiss the view to return to the previous screen
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Dr. \(doctor.full_name) has been \(doctor.is_active ? "activated" : "deactivated") successfully.")
        }
        .task {
            if let departmentId = doctor.department_id {
                if let department = await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
                    departmentName = department.name
                }
            }
        }
        .disabled(isUpdating)
        .navigationTitle("Doctor Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleDoctorStatus() async {
        isUpdating = true
        errorMessage = nil
        
        // Create a copy of the doctor with toggled active status
        var updatedDoctor = doctor
        updatedDoctor.is_active.toggle()
        
        do {
            // Use the correct table name "Doctor" (not "Doctors")
            try await supabaseController.client
                .from("Doctor")
                .update(updatedDoctor)
                .eq("id", value: updatedDoctor.id.uuidString)
                .execute()
            
            // Update the local state
            doctor = updatedDoctor
            showStatusChangeAlert = true
            print("Successfully updated doctor status to: \(updatedDoctor.is_active)")
        } catch {
            print("Error updating doctor status: \(error.localizedDescription)")
            errorMessage = "Failed to update status: \(error.localizedDescription)"
        }
        
        isUpdating = false
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


