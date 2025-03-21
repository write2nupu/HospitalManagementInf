import SwiftUI

struct DoctorProfileView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    let doctor: Doctor
    
    @State private var doctorDetails: Doctor?
    @State private var departmentDetails: Department?
    
    @State private var isLoggedOut = false
    
    var body: some View {
        NavigationStack {
            Form {
//                Section(header: Text("Available Slots")) {
//                    ForEach(doctor.availableSlots, id: \.self) { slot in
//                        slotSetUp(slot: slot, isAvailable: checkAvailability(for: slot))
//                    }
//                }
                
//                Section(header: Text("Consultation Fee")) {
//                    profileRow(title: "Fee", value: "₹\(String(format: "%.2f", doctor.consultationFee))")
//                }
                
                Section(header: Text("Basic Information")) {
                    profileRow(title: "Full Name", value: doctor.fullName)
                    if let department = departmentDetails {
                        profileRow(title: "Department", value: department.name)
                    }
                    profileRow(title: "Qualifications", value: doctor.qualifications)
                    profileRow(title: "Experience", value: "\(doctor.experience) years")
                    profileRow(title: "License Number", value: doctor.licenseNumber)
                    profileRow(title: "Gender", value: doctor.gender)
                }
                
                Section(header: Text("Contact Information")) {
                    profileRow(title: "Phone", value: doctor.phoneNumber)
                    profileRow(title: "Email", value: doctor.email)
                }
                
                Section {
                    NavigationLink(destination: updateFields(doctor: doctor)) {
                        Text("Edit Phone and Email")
                            .foregroundColor(AppConfig.buttonColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    NavigationLink(destination: updatePassword(doctor: doctor)) {
                        Text("Update Password")
                            .foregroundColor(AppConfig.buttonColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    Button(action: handleLogout) {
                        Text("Logout")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                if let department = departmentDetails {
                    Section(header: Text("Consultation Fee")) {
                        profileRow(title: "Fee", value: "₹\(String(format: "%.2f", department.fees))")
                    }
                }
            }
            .navigationTitle("Doctor Profile")
            .tint(AppConfig.buttonColor)
            .fullScreenCover(isPresented: .constant(isLoggedOut)) {
                UserRoleScreen()
            }
            .task {
                if let departmentId = doctor.departmentId {
                    departmentDetails = await supabaseController.fetchDepartmentDetails(departmentId: departmentId)
                }
            }
        }
    }
    
    // ✅ Move these functions OUTSIDE the body
    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title).fontWeight(.none)
            Spacer()
            Text(value).foregroundColor(.gray)
        }
    }
    
    private func slotSetUp(slot: String, isAvailable: Bool) -> some View {
        HStack {
            Text(slot) // Display slot name (Morning / Evening)
                .fontWeight(.regular)
            
            Spacer()
            
            Text(isAvailable ? "Available" : "Not Available") // Show status
                .foregroundColor(isAvailable ? .green : .red)
                .fontWeight(.semibold)
        }
        .cornerRadius(8)
    }
    
    private func checkAvailability(for slot: String) -> Bool {
        return true
    }
    
    private func handleLogout() {
        isLoggedOut = true
    }
}

// ✅ Preview
#Preview {
    DoctorProfileView(doctor: Doctor(id: UUID(), fullName: "Anubahv", experience: 10, qualifications: "Tumse Jayda", isActive: true, phoneNumber: "1234567898", email: "tumkopatanahihonichahiye@gmail.com", gender: "male", licenseNumber: "123-456-789"))
}
