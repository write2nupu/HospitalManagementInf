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
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn && !currentUserId.isEmpty {
                // User is logged in, show appropriate view based on role
                switch userRole {
                case "admin":
                    AdminTabView()
                case "super_admin":
                    ContentView()
                case "doctor":
                    mainBoard()
                case "patient":
                    PatientDashboard(patient: self.patient!)
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
