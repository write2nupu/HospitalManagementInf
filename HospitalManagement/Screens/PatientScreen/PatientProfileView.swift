//
//  PatientProfileView.swift
//  HospitalManagement
//
//  Created by Nupur on 21/03/25.
//

import SwiftUI

struct ProfileView: View {
    @Binding var patient: Patient
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Icon
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.mint)
                    .padding(.top, 40)
                
                // Patient Info
                VStack(alignment: .leading, spacing: 10) {
                    ProfileRow(title: "Full Name", value: patient.fullName)
                    ProfileRow(title: "Patient ID", value: patient.id.uuidString)
                    ProfileRow(title: "Phone", value: patient.phoneNumber)
                    ProfileRow(title: "Email", value: patient.email)
                    if let details = patient.detailId {
                        ProfileRow(title: "Blood Group", value: details.uuidString)
                    }
                }
                .padding()
                .background(Color.mint.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(leading: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .fontWeight(.semibold)
                .foregroundColor(.mint)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}
