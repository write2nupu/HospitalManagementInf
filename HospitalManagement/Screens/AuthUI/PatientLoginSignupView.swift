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
    @State private var isLoading = false
    @State private var showDashboard = false
    @State private var showForgotPassword = false
    @State private var showOTPVerification = false
    @StateObject private var supabaseController = SupabaseController()
    @State private var currentPatient: Patient?
    @State private var isEmailValid = true
    @State private var isPasswordValid = true
    @State private var emailErrorMessage = ""
    @State private var passwordErrorMessage = ""
    
    // Computed property to check if login form is valid
    private var isLoginFormValid: Bool {
        // Only consider form valid when:
        // 1. Both fields are not empty
        // 2. Email format is valid
        // 3. Password meets all requirements
        return !email.isEmpty && isValidEmail(email) && 
               !password.isEmpty && isValidPassword(password)
    }
    
    var body: some View {
        Group {
            if showDashboard, let patient = currentPatient {
                // When logged in, replace entire view with PatientDashboard
                PatientDashboard(patient: patient)
                    .navigationBarBackButtonHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
            } else {
                // Login UI
                VStack(spacing: 30) {
                    // Title
                    VStack(spacing: 5) {
                        Image("patient")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
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
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundColor(.mint)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    .padding(.top, -10)
                    
                    
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
                    .background(isLoginFormValid ? Color.mint : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isLoading || !isLoginFormValid)
                    
                    // Signup Button
                    NavigationLink(destination: PatientSignupView()) {
                        HStack(spacing: 0) {
                            Text("Don't have an account? ")
                                .font(.body)
                                .foregroundColor(.primary)
                            
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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(isPresented: $showOTPVerification) {
            OTPVerificationView(
                email: email,
                onVerificationComplete: {
                    showOTPVerification = false
                    Task {
                        await completeLogin()
                    }
                },
                onCancel: {
                    showOTPVerification = false
                    isLoading = false
                }
            )
        }
    }
    
    // MARK: - Submission Logic
    func handleSubmit() async {
        // Reset validation states
        isEmailValid = true
        isPasswordValid = true
        emailErrorMessage = ""
        passwordErrorMessage = ""
        
        // Validate email
        if email.isEmpty {
            isEmailValid = false
            emailErrorMessage = "Email cannot be empty"
            alertMessage = "Please enter your email"
            showAlert = true
            return
        } else if !isValidEmail(email) {
            isEmailValid = false
            emailErrorMessage = "Invalid email format"
            alertMessage = "Please enter a valid email"
            showAlert = true
            return
        }
        
        // Validate password
        if password.isEmpty {
            isPasswordValid = false
            passwordErrorMessage = "Password cannot be empty"
            alertMessage = "Please enter your password"
            showAlert = true
            return
        } else if !isValidPassword(password) {
            isPasswordValid = false
            passwordErrorMessage = "Password must be at least 8 characters with 1 number, 1 letter, and 1 special character"
            alertMessage = "Password must be at least 8 characters with 1 number, 1 letter, and 1 special character"
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // First check if patient exists
            let patients: [Patient] = try await supabaseController.client
                .from("Patient")
                .select()
                .eq("email", value: email)
                .execute()
                .value
            
            if let patient = patients.first {
                // Send OTP
                try await supabaseController.sendOTP(email: email)
                showOTPVerification = true
            } else {
                alertMessage = "No account found with this email"
                showAlert = true
                isLoading = false
            }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
            isLoading = false
        }
    }
    
    private func completeLogin() async {
        do {
            // After OTP verification, proceed with sign in
            currentPatient = try await supabaseController.signInPatient(email: email, password: password)
            
            // Set all required UserDefaults for persistence
            UserDefaults.standard.set(true, forKey: "isLoggedIn") // Set logged in flag
            UserDefaults.standard.set(currentPatient?.id.uuidString, forKey: "currentUserId") // Set user ID
            UserDefaults.standard.set("patient", forKey: "userRole") // Set role
            
            print("✅ Patient login successful - ID: \(currentPatient?.id.uuidString ?? "unknown"), storing in UserDefaults")
            showDashboard = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
        isLoading = false
    }
    
    // MARK: - Validation Functions
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters
        guard password.count >= 8 else { return false }
        
        // At least one numeric character
        let numberRegex = ".*[0-9]+.*"
        let numberPredicate = NSPredicate(format:"SELF MATCHES %@", numberRegex)
        guard numberPredicate.evaluate(with: password) else { return false }
        
        // At least one alphabetic character
        let letterRegex = ".*[a-zA-Z]+.*"
        let letterPredicate = NSPredicate(format:"SELF MATCHES %@", letterRegex)
        guard letterPredicate.evaluate(with: password) else { return false }
        
        // At least one special character
        let specialCharRegex = ".*[^A-Za-z0-9].*"
        let specialCharPredicate = NSPredicate(format:"SELF MATCHES %@", specialCharRegex)
        guard specialCharPredicate.evaluate(with: password) else { return false }
        
        return true
    }
    
    // MARK: - Helper Views
    func customTextField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.mint)
                TextField(placeholder, text: text)
                    .autocapitalization(.none)
                    .keyboardType(keyboardType)
                    .onChange(of: text.wrappedValue) { oldValue, newValue in
                        if icon == "envelope.fill" {
                            isEmailValid = isValidEmail(newValue)
                            if !isEmailValid && !newValue.isEmpty {
                                emailErrorMessage = "Invalid email format"
                            } else {
                                emailErrorMessage = ""
                            }
                        }
                    }
            }
            .padding()
            .background(Color.mint.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if icon == "envelope.fill" && !isEmailValid && !emailErrorMessage.isEmpty {
                Text(emailErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    func passwordField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.mint)
                
                if isPasswordVisible {
                    TextField(placeholder, text: text)
                        .autocapitalization(.none)
                        .onChange(of: text.wrappedValue) { oldValue, newValue in
                            isPasswordValid = isValidPassword(newValue)
                            if !isPasswordValid && !newValue.isEmpty {
                                passwordErrorMessage = "Password must be at least 8 characters with 1 number, 1 letter, and 1 special character"
                            } else {
                                passwordErrorMessage = ""
                            }
                        }
                } else {
                    SecureField(placeholder, text: text)
                        .onChange(of: text.wrappedValue) { oldValue, newValue in
                            isPasswordValid = isValidPassword(newValue)
                            if !isPasswordValid && !newValue.isEmpty {
                                passwordErrorMessage = "Password must be at least 8 characters with 1 number, 1 letter, and 1 special character"
                            } else {
                                passwordErrorMessage = ""
                            }
                        }
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
            
            if !isPasswordValid && !passwordErrorMessage.isEmpty {
                Text(passwordErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Preview
struct PatientLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PatientLoginSignupView()
    }
}

