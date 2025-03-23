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
    @State private var shouldShowUserRoleScreen = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if shouldShowUserRoleScreen {
                    UserRoleScreen()
                } else {
                    UserRoleScreen()
                }
            }
            .environmentObject(viewModel)
            .onAppear {
                // Setup notification observer
                NotificationCenter.default.addObserver(
                    forName: .init("LogoutNotification"),
                    object: nil,
                    queue: .main
                ) { _ in
                    shouldShowUserRoleScreen = true
                }
            }
        }
    }
}
