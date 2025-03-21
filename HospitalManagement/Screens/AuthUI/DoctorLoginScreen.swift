//
//  DoctorLoginScreen.swift
//  HospitalManagement
//
//  Created by Nupur on 21/03/25.
//

import SwiftUI

struct DoctorLoginView: View {
    @State private var doctorID: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Doctor Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.mint)
                    .padding(.top, 40)
                
                TextField("Doctor ID", text: $doctorID)
                    .padding()
                    .background(Color.mint.opacity(0.1))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.mint.opacity(0.1))
                    .cornerRadius(10)
                
                Button(action: {
                    isLoggedIn = true
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mint)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(isPresented: $isLoggedIn) {
                DashBoard()
            }
        }
    }
}


struct DoctorLoginView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorLoginView()
    }
}

