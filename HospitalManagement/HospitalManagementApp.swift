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
    @State private var isLoggedIn = false
    @State private var userRole: String? = nil
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var patient: Patient?
    @StateObject private var supabaseController = SupabaseController()
    
    var body: some Scene {
        WindowGroup {
            UserRoleScreen()
                .environmentObject(viewModel)
                .onAppear {
                    // Clear any stored login state on app launch
                    UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                    UserDefaults.standard.removeObject(forKey: "userRole")
                    
                    // Create default super admin
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
