//
//  SuperAdmin.swift
//  HospitalManagement
//
//  Created by Mariyo on 21/03/25.
//

import Foundation
import SwiftUI

struct SuperAdminLoginView: View {
    var message: String
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var isPasswordVisible = false
    @StateObject private var supabaseController = SupabaseController()
    @State private var isLoading = false

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
                    customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $emailOrPhone, keyboardType: .emailAddress)
                }

                // Password Input
                VStack(alignment: .leading, spacing: 5) {
                    passwordField(icon: "lock.fill", placeholder: "Enter Password", text: $password)
                }

                // Login Button
                Button(action: {
                    Task {
                        await handleLogin()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.mint)
                .cornerRadius(12)
                .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
                .disabled(isLoading)
                .padding(.horizontal)
                .padding(.top, 20)

                // Navigation Trigger after Successful Login
                NavigationLink(destination: forcePasswordUpdate(), isActive: $isLoggedIn) { EmptyView() }

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
    
    
    
    
    
    private func handleLogin() async {
        guard !emailOrPhone.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            showAlert = true
            return
        }
        
        isLoading = true
        do {
            let user = try await supabaseController.signIn(email: emailOrPhone, password: password)
            // Check if user has super admin role
            if user.role.rawValue == "super_admin" {
                isLoggedIn = true
                print("Logged in successfully as Super Admin")
                // Store the user ID for future use
                UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserId")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
            } else {
                errorMessage = "Access denied. You must be a Super Admin to login."
                showAlert = true
            }
        } catch {
            errorMessage = "Invalid credentials or network error. Please try again."
            showAlert = true
            print("Login error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    
    
    // MARK: - Helper Views
    func customTextField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.mint)
            TextField(placeholder, text: text)
                .autocapitalization(.none)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color.mint.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    func passwordField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.mint)
            
            if isPasswordVisible {
                TextField(placeholder, text: text)
            } else {
                SecureField(placeholder, text: text)
            }
            
            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.mint.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Preview
#Preview {
    SuperAdminLoginView(message: "Super Admin")
}
