
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
                        .foregroundColor(AppConfig.fontColor)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    Form {
                        Section("Super Admin Information") {
                            if let admin = superAdmin {
                                ProfileDetailRow(title: "Name", value: admin.full_name)
                                    .foregroundColor(AppConfig.fontColor)
                                ProfileDetailRow(title: "Email", value: admin.email)
                                    .foregroundColor(AppConfig.fontColor)
                                ProfileDetailRow(title: "Role", value: "Super Administrator")
                                    .foregroundColor(AppConfig.fontColor)
                            }
                        }
                        .foregroundStyle(AppConfig.fontColor)
                        
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
                        .foregroundStyle(AppConfig.fontColor)
                    }
                    .background(AppConfig.backgroundColor)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Done") { dismiss() }
                .foregroundColor(AppConfig.buttonColor))
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
        Task {
            do {
                // Sign out the user from Supabase authentication
                try await supabaseController.client.auth.signOut()
                
                // Update local state
                userRole = nil
                isLoggedIn = false
                
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

#Preview {
    SuperAdminProfileView()
}
