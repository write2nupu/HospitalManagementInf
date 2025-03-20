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
    
    var body: some Scene {
        WindowGroup {
            UserRoleScreen()
                .environmentObject(viewModel)
        }
    }
}
