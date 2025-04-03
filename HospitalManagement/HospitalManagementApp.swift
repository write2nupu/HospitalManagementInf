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
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @AppStorage("userRole") private var userRole: String = ""
    @State private var patient: Patient?
    @StateObject private var supabaseController = SupabaseController()
    @State private var isLoading = false
    
    var body: some Scene {
        WindowGroup {
            if isLoading {
                LoadingView()
                    .onAppear {
                        loadPatientData()
                    }
            } else if isLoggedIn && !currentUserId.isEmpty {
                // User is logged in, show appropriate view based on role
                switch userRole {
                case "admin":
                    AdminTabView()
                        .environmentObject(viewModel)
                case "super_admin":
                    ContentView()
                case "doctor":
                    mainBoard()
                case "patient":
                    if let patient = self.patient {
                        PatientDashboard(patient: patient)
                    } else {
                        LoadingView()
                            .onAppear {
                                loadPatientData()
                            }
                    }
                default:
                    UserRoleScreen()
                }
            } else {
                // User is not logged in, show role selection
                UserRoleScreen()
                    .environmentObject(viewModel)
                    .onAppear {
                        // Create default super admin if needed
                        Task {
                            do {
                                try await supabaseController.createDefaultSuperAdmin()
                            } catch {
                                print("Error creating default super admin: \(error)")
                            }
                        }
                    }
            }
        }
    }
    
    private func loadPatientData() {
        if isLoggedIn && userRole == "patient" && !currentUserId.isEmpty {
            isLoading = true
            
            Task {
                do {
                    if let patientId = UUID(uuidString: currentUserId) {
                        print("🔄 Loading patient data for ID: \(patientId)")
                        if let fetchedPatient = try await supabaseController.fetchPatientById(patientId: patientId) {
                            await MainActor.run {
                                self.patient = fetchedPatient
                                self.isLoading = false
                                print("✅ Successfully loaded patient data")
                            }
                        } else {
                            print("❌ Could not find patient with ID: \(patientId)")
                            await MainActor.run {
                                // Reset login state if patient not found
                                self.isLoggedIn = false
                                self.currentUserId = ""
                                self.userRole = ""
                                self.isLoading = false
                            }
                        }
                    } else {
                        print("❌ Invalid UUID format for patient ID: \(currentUserId)")
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                } catch {
                    print("❌ Error loading patient data: \(error)")
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
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
