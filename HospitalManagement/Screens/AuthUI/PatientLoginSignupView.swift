//
//  PatientLoginSignupView.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 21/03/25.
//

import SwiftUI

struct PatientLoginSignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToDashboard = false
    @State private var isLoading = false
    @AppStorage("isLoggedIn") private var isUserLoggedIn = false
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @StateObject private var supabaseController = SupabaseController()
    
    @State private var currentPatient: Patient?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Title
                VStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.mint)
                        .padding(.bottom, 10)

                    // **Title**
                    Text("Patient")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 20) {
                    customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $email, keyboardType: .emailAddress)
                    passwordField(icon: "lock.fill", placeholder: "Enter Password", text: $password)
                }
                .padding(.top, 20)
                
                // Login Button
                Button(action: {
                    Task {
                        await handleSubmit()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.mint)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isLoading)
                
                // Signup Button
                NavigationLink(destination: PatientSignupView()) {
                    HStack(spacing: 0) {
                        Text("Don't have an account? ")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.mint)
                    }
                    .padding(.top, 10)
                    .background(Color.clear)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.mint.opacity(0.05))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Action Required"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Submission Logic
    func handleSubmit() async {
        if email.isEmpty || password.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            currentPatient = try await supabaseController.signInPatient(email: email, password: password)
            currentUserId = currentPatient?.id.uuidString ?? ""
            isUserLoggedIn = true
            UserDefaults.standard.set("Patient", forKey: "userRole")
            
            // We don't need to navigate using the overlay anymore
            // The app will automatically show the dashboard based on isLoggedIn and userRole
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
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

// MARK: - Preview
struct PatientLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PatientLoginSignupView()
    }
}

