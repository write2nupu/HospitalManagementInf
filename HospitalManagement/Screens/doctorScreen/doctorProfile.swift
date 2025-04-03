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
                Section(header: Text("Basic Information")) {
                    profileRow(title: "Full Name", value: doctorDetails?.full_name ?? doctor.full_name)
                    if let department = departmentDetails {
                        profileRow(title: "Department", value: department.name)
                    }
                    profileRow(title: "Qualifications", value: doctorDetails?.qualifications ?? doctor.qualifications)
                    profileRow(title: "Experience", value: "\(doctorDetails?.experience ?? doctor.experience) years")
                    profileRow(title: "License Number", value: doctorDetails?.license_num ?? doctor.license_num)
                    profileRow(title: "Gender", value: doctorDetails?.gender ?? doctor.gender)
                }
                
                Section(header: Text("Contact Information")) {
                    profileRow(title: "Phone", value: doctorDetails?.phone_num ?? doctor.phone_num)
                    profileRow(title: "Email", value: doctorDetails?.email_address ?? doctor.email_address)
                }
                
                Section {
                    NavigationLink(destination: updateFields(doctor: doctorDetails ?? doctor)) {
                        Text("Edit Contact Information")
                            .foregroundColor(AppConfig.buttonColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    NavigationLink(destination: UpdateQualificationsView(doctor: doctorDetails ?? doctor)) {
                        Text("Update Qualifications")
                            .foregroundColor(AppConfig.buttonColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    NavigationLink(destination: LeaveApplicationView(Doctor: doctorDetails ?? doctor)) {
                        Text("Doctor Leave")
                            .foregroundColor(AppConfig.buttonColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    NavigationLink(destination: updatePassword(doctor: doctorDetails ?? doctor)) {
                        Text("Reset Password")
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
            .navigationBarTitleDisplayMode(.inline)
            
            .tint(AppConfig.buttonColor)
            .fullScreenCover(isPresented: .constant(isLoggedOut)) {
                UserRoleScreen()
            }
            .task {
                await fetchDoctorDetails()
            }
            .onAppear {
                Task {
                    await fetchDoctorDetails()
                }
            }
        }
    }
    
    private func fetchDoctorDetails() async {
        // Fetch updated doctor details
        do {
            let doctors: [Doctor] = try await supabaseController.client
                .from("Doctor")
                .select()
                .eq("id", value: doctor.id.uuidString)
                .execute()
                .value
            
            if let updatedDoctor = doctors.first {
                doctorDetails = updatedDoctor
            }
            
            // Fetch department details
            if let departmentId = doctorDetails?.department_id ?? doctor.department_id {
                departmentDetails = await supabaseController.fetchDepartmentDetails(departmentId: departmentId)
            }
        } catch {
            print("Error fetching doctor details:", error)
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
    
    private func handleLogout() {
        Task {
            do {
                // Sign out the user from Supabase authentication
                try await SupabaseController().client.auth.signOut()
                
                // Clear user data from UserDefaults
                UserDefaults.standard.removeObject(forKey: "currentUserId")
                UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                UserDefaults.standard.removeObject(forKey: "userRole")
                
                // Redirect to the user role screen
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: UserRoleScreen())
                    window.makeKeyAndVisible()
                }
                
                isLoggedOut = true
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    }
}


