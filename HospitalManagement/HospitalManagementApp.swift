//
//  HospitalManagementApp.swift
//  HospitalManagement
//
//  Created by Nupur on 18/03/25.
//

import SwiftUI

@main
struct HospitalManagementApp: App {
    @StateObject private var viewModel = HospitalManagementViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var userRole: String?
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var patient: Patient?
    @StateObject private var supabaseController = SupabaseController()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    if let userRole = userRole {
                        switch userRole {
                        case "Patient":
                            if let patient = patient {
                                PatientDashboard(patient: patient)
                            } else {
                                // Loading state while fetching patient data
                                LoadingView()
                                    .onAppear {
                                        fetchLoggedInPatient()
                                    }
                            }
                        case "Doctor":
                            Text("Doctor Dashboard")
                            // Replace with actual doctor dashboard
                        case "Admin":
                            Text("Admin Dashboard")
                            // Replace with actual admin dashboard
                        case "Super-Admin":
                            Text("Super Admin Dashboard")
                            // Replace with actual super admin dashboard
                        default:
                            UserRoleScreen()
                        }
                    } else {
                        UserRoleScreen()
                    }
                } else {
                    UserRoleScreen()
                }
            }
            .environmentObject(viewModel)
            .onAppear {
                // Create default super admin
                Task {
                    do {
                        try await supabaseController.createDefaultSuperAdmin()
                    } catch {
                        print("Error creating default super admin: \(error)")
                    }
                }
                
                // Setup notification observer
                NotificationCenter.default.addObserver(
                    forName: .init("LogoutNotification"),
                    object: nil,
                    queue: .main
                ) { _ in
                    isLoggedIn = false
                    userRole = nil
                    currentUserId = ""
                    patient = nil
                }
            }
        }
    }
    
    private func fetchLoggedInPatient() {
        Task {
            do {
                if let userId = UUID(uuidString: currentUserId) {
                    let fetchedPatient = try await supabaseController.fetchPatient(id: userId)
                    await MainActor.run {
                        self.patient = fetchedPatient
                    }
                }
            } catch {
                print("Error fetching patient: \(error)")
            }
        }
    }
}

// Simple loading view
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(2)
                .padding()
            Text("Loading...")
                .font(.headline)
                .padding()
        }
    }
}
