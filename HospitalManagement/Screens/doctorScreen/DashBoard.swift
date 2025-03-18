//
//  DashBoard.swift
//  HospitalManagement
//
//  Created by Anubhav Dubey on 18/03/25.
//

import SwiftUI

struct DashBoard: View {
    var doctorName: String = "Dr. Anubhav Dubey" // Change dynamically later

    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea() // Background color
                
                VStack(spacing: 20) {
                    // **Top Bar with Profile Button**
                    HStack {
                        Spacer() // Push button to the right
                        Button(action: {
                            print("Profile Button Tapped")
                            // Navigate to Profile Screen
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(AppConfig.buttonColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // **Welcome Message**
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Welcome,")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundColor(.primary)
                        
                        Text(doctorName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // **Quick Actions Grid**
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            QuickActionButton(icon: "calendar", title: "Appointments")
                            QuickActionButton(icon: "person.2.fill", title: "Patients")
                        }
                        HStack(spacing: 15) {
                            QuickActionButton(icon: "doc.text.fill", title: "Reports")
                            QuickActionButton(icon: "message.fill", title: "Messages")
                        }
                    }
                    .padding(.top, 10)

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

// **Reusable Quick Action Button**
struct QuickActionButton: View {
    let icon: String
    let title: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color.blue))
                .shadow(radius: 5)

            Text(title)
                .font(.footnote)
                .foregroundColor(.primary)
        }
        .frame(width: 100, height: 100)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))
    }
}

// **Preview**
#Preview {
    NavigationView {
        DashBoard()
    }
}
