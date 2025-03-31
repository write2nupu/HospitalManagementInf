////
////  profile.swift
////  HospitalManagement
////
////  Created by Nikhil Gupta on 21/03/25.
////
//import SwiftUI
//
//
//struct SuperAdminProfileView: View {
//    @Environment(\.dismiss) private var dismiss
//    @State private var isLoggedOut = false
//    var body: some View {
//        NavigationView {
//            Form {
//                Section("Super Admin Information") {
//                    HStack {
//                        Text("Name:")
//                        Spacer()
//                        Text("Super Admin")
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    HStack {
//                        Text("Email:")
//                        Spacer()
//                        Text("admin@example.com")
//                            .foregroundColor(.secondary)
//                    }
//                   
//                    }
//                Section {
//                    Button(action: handleLogout) {
//                        Text("Logout")
//                            .fontWeight(.bold)
//                            .foregroundColor(.red)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                    }
//                }
//                .navigationTitle("Profile")
//                .navigationBarItems(trailing: Button("Done") { dismiss() })
//                .fullScreenCover(isPresented: .constant(isLoggedOut)) {
//                    UserRoleScreen()
//                }
//            }
//        }
//    }
//    private func handleLogout() {
//        isLoggedOut = true
//    }
//}



//
//  profile.swift
//  HospitalManagement
//
//  Created by Nikhil Gupta on 21/03/25.
//

import SwiftUI

struct SuperAdminProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseController()
    @State private var isLoggedOut = false
    @State private var showLogoutAlert = false
    @State private var superAdmin: users?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var userRole: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading profile...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    Form {
                        Section("Super Admin Information") {
                            if let admin = superAdmin {
                                ProfileDetailRow(title: "Name", value: admin.full_name)
                                ProfileDetailRow(title: "Email", value: admin.email)
                                ProfileDetailRow(title: "Role", value: "Super Administrator")
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
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(leading: Button("Done") { dismiss() })
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .fullScreenCover(isPresented: .constant(isLoggedOut)) {
                UserRoleScreen()
            }
            .onAppear {
                Task {
                    await loadSuperAdminProfile()
                }
            }
        }
    }
    
    private func loadSuperAdminProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let superAdmin = try await supabaseController.fetchSuperAdminProfile() {
                print("Fetched super admin details - Name: \(superAdmin.full_name), Email: \(superAdmin.email)")
                await MainActor.run {
                    self.superAdmin = superAdmin
                    isLoading = false
                }
            } else {
                print("No super admin found in the database")
                await MainActor.run {
                    errorMessage = "Could not find super admin profile"
                    isLoading = false
                }
            }
        } catch {
            print("Error loading super admin profile: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Error loading profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func handleLogout() {
        userRole = nil
        isLoggedIn = false
        NotificationCenter.default.post(name: .init("LogoutNotification"), object: nil)
        isLoggedOut = true
    }
}

#Preview {
    SuperAdminProfileView()
}
