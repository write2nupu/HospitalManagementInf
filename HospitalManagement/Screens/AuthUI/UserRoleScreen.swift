//
//  RoleSelectionView.swift
//  HospitalManagement
//
//  Created by Nupur on 19/03/25.
//

import SwiftUI

struct UserRoleScreen: View {
    let roles = ["Patient", "Doctor", "Admin", "Super-Admin"]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Main title with image
                VStack(spacing: 20) {
                    Image("role")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    Text("Select Your Role")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.top, 40)
                
                Spacer()
                
                ForEach(roles, id: \.self) { role in
                        if role == "Patient" {
                            NavigationLink(destination: PatientLoginSignupView()) {
                                RoleCard(role: role, imageName: "patient")
                            }
                        }
                    
                    else if role == "Doctor" {
                        NavigationLink(destination: DoctorLoginView(message: "Doctor")) {
                            RoleCard(role: role, imageName: "doctor")
                        }
                    }
                    else if role == "Admin" {

                        NavigationLink(destination: AdminLoginViewS(message: "Admin")) {
                            RoleCard(role: role, imageName: "admin")
                        }
                    }
                    else if role == "Super-Admin" {

                        NavigationLink(destination: SuperAdminLoginView(message: "Super admin")) {

                            RoleCard(role: role, imageName: "superadmin")
                        }
                    }
    
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Role Card
struct RoleCard: View {
    var role: String
    var imageName: String
    
    var body: some View {
        HStack {
            // Role image
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(.trailing, 10)
            
            Text(role)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.mint)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.mint)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)  // Increased height to 100
        .background(Color.mint.opacity(0.2))
        .cornerRadius(15)
        .padding(.vertical, 10)
        .shadow(color: .mint.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}


// MARK: - Preview
struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        UserRoleScreen()
    }
}



