//
//  AdminLoginView.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 20/03/25.
//


import SwiftUI

struct AdminLoginView: View {
    @State var message:String
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // App Logo
                Image(systemName: "building.columns.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.mint)
                    .padding(.bottom, 10)
                
                // Title
                Text(message)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                
                // Email/Phone Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email or Phone")
                        .font(.headline)
                        .foregroundColor(.gray)
                    TextField("Enter your email or phone", text: $emailOrPhone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                // Password Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.gray)
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
//                // Role Selection
//                VStack(alignment: .leading, spacing: 5) {
//                    Text("Select Role")
//                        .font(.headline)
//                        .foregroundColor(.gray)
//                    Picker("Role", selection: $selectedRole) {
//                        Text("Admin").tag("Admin")
//                        Text("Super Admin").tag("Super Admin")
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                }
                
                // Login Button
                Button(action: handleLogin) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .cornerRadius(12)
                        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 20)

                Spacer() // Push content upward
            }
            .padding()
            .background(Color.mint.opacity(0.05))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Login Logic
    private func handleLogin() {
        if emailOrPhone.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields."
            showAlert = true
        } else {
            // Add logic for successful login navigation here
            print("Logged in successfully.")
        }
    }
}

// ✅ Preview
#Preview {
    AdminLoginView(message: "Admin")
}
