//
//  PatientLoginSignupView.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 21/03/25.
//

import SwiftUI

struct PatientLoginSignupView: View {
    @State private var selectedSegment = 0
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToDashboard = false
    @State private var navigateToSignUp = false
    @State private var isLoading = false
    @AppStorage("isLoggedIn") private var isUserLoggedIn = false
    @StateObject private var supabaseController = SupabaseController()
    
    @State private var currentPatient: Patient?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                // Title
                VStack(spacing: 5) {
                    Text("Patient Portal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)
                    
                    Text("Welcome! Please \(selectedSegment == 0 ? "Login" : "Sign Up")")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)

                // Segmented Control
                Picker("Mode", selection: $selectedSegment) {
                    Text("Login").tag(0)
                    Text("Signup").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Form Fields
                VStack(spacing: 20) {
                    customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $email, keyboardType: .emailAddress)

                    passwordField(icon: "lock.fill", placeholder: selectedSegment == 0 ? "Enter Password" : "Create Password", text: $password)

                    if selectedSegment == 1 {
                        passwordField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword)
                    }
                }
                .padding(.top, 20)

                // Submit Button
                Button(action: {
                    Task {
                        await handleSubmit()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(selectedSegment == 0 ? "Login" : "Sign Up")
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

                Spacer()
            }
            .padding()
            .background(Color.mint.opacity(0.05))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Action Required"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $navigateToDashboard) {
                if let patient = currentPatient {
                    PatientDashboard(patient: patient)
                }
            }
            .navigationDestination(isPresented: $navigateToSignUp) {
                PatientSignupView()
            }
        }
    }

    // MARK: - Submission Logic
    func handleSubmit() async {
        if email.isEmpty || password.isEmpty || (selectedSegment == 1 && confirmPassword.isEmpty) {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            return
        }
        
        if selectedSegment == 1 && password != confirmPassword {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            if selectedSegment == 0 { // Login
                currentPatient = try await supabaseController.signInPatient(email: email, password: password)
                isUserLoggedIn = true
                navigateToDashboard = true
            } else { // Sign Up
                navigateToSignUp = true
            }
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
struct PatientLoginSignupView_Previews: PreviewProvider {
    static var previews: some View {
        PatientLoginSignupView()
    }
}

