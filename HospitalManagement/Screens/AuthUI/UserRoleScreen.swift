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
                Image("role")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                Text("Select Your Role")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 40)
                
                Spacer()
                
                ForEach(roles, id: \.self) { role in
                    NavigationLink(destination: getDestinationForRole(role)) {
                        RoleCard(role: role)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func getDestinationForRole(_ role: String) -> some View {
        switch role {
        case "Patient":
            PatientLoginSignupView()
        case "Doctor":
            DoctorLoginView(message: "Doctor")
        case "Admin":
            AdminLoginViewS(message: "Admin")
        case "Super-Admin":
            SuperAdminLoginView(message: "Super admin")
        default:
            EmptyView()
        }
    }
}

// MARK: - Role Card
struct RoleCard: View {
    var role: String
    
    var body: some View {
        HStack {
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
