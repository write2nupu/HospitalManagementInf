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
    @State private var isLoggedOut = false
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section("Super Admin Information") {
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text("Super Admin")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email:")
                        Spacer()
                        Text("admin@example.com")
                            .foregroundColor(.secondary)
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
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .fullScreenCover(isPresented: .constant(isLoggedOut)) {
                UserRoleScreen()
            }
        }
    }
    
    private func handleLogout() {
        isLoggedOut = true
    }
}
