import SwiftUI

struct DoctorProfileView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    let doctor: Doctor
    
    @State private var doctorDetails: Doctor?
    @State private var departmentDetails: Department?
    
    @State private var isLoggedOut = false
    @State private var showLogoutAlert = false
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
                    profileRow(title: "Full Name", value: doctor.full_name)
                    if let department = departmentDetails {
                        profileRow(title: "Department", value: department.name)
                    }
                    profileRow(title: "Qualifications", value: doctor.qualifications)
                    profileRow(title: "Experience", value: "\(doctor.experience) years")
                    profileRow(title: "License Number", value: doctor.license_num)
                    profileRow(title: "Gender", value: doctor.gender)
                }
                
                Section(header: Text("Contact Information")) {
                    profileRow(title: "Phone", value: doctor.phone_num)
                    profileRow(title: "Email", value: doctor.email_address)
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
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Text("Logout")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Logout"),
                            message: Text("Are you sure you want to logout?"),
                            primaryButton: .destructive(Text("Logout")) {
                                handleLogout()
                            },
                            secondaryButton: .cancel()
                        )
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
                // Fetch doctor details
                if let departmentId = doctor.department_id {
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


