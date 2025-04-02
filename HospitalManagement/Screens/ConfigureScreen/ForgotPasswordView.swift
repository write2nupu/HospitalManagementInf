import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseController()
    
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    
    // For the verification code & new password
    @State private var showResetSection = false
    @State private var verificationCode: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // App Logo
                    Image(systemName: "key.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.mint)
                        .padding(.top, 40)
                    
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)
                    
                    if !showResetSection {
                        // Email verification section
                        VStack(spacing: 20) {
                            Text("Enter your email address and we'll send you instructions to reset your password.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $email, keyboardType: .emailAddress)
                            
                            Button(action: {
                                Task {
                                    await sendResetLink()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Send Reset Link")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidEmail(email) ? Color.mint : Color.gray)
                            .cornerRadius(12)
                            .disabled(!isValidEmail(email) || isLoading)
                            .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    } else {
                        // Reset password section
                        VStack(spacing: 20) {
                            Text("Enter the verification code from your email and set a new password.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            customTextField(icon: "number", placeholder: "Verification Code", text: $verificationCode, keyboardType: .numberPad)
                            
                            passwordField(icon: "lock.fill", placeholder: "New Password", text: $newPassword, isVisible: $isPasswordVisible)
                            
                            passwordField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isVisible: $isConfirmPasswordVisible)
                            
                            Button(action: {
                                Task {
                                    await resetPassword()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Reset Password")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidReset() ? Color.mint : Color.gray)
                            .cornerRadius(12)
                            .disabled(!isValidReset() || isLoading)
                            .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back to Login")
                            .foregroundColor(.mint)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.mint.opacity(0.05))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess && !showResetSection {
                            // If email was sent successfully, show the reset section
                            showResetSection = true
                        } else if isSuccess && showResetSection {
                            // If password was reset successfully, dismiss the view
                            dismiss()
                        }
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.mint)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendResetLink() async {
        guard isValidEmail(email) else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Check if user exists in the system
            let userExists = await checkUserExists(email: email)
            
            if !userExists {
                alertTitle = "User Not Found"
                alertMessage = "No account found with this email address."
                showAlert = true
                isLoading = false
                return
            }
            
            // Send password recovery email
            try await supabaseController.client.auth.resetPasswordForEmail(email)
            
            alertTitle = "Email Sent"
            alertMessage = "Check your email for a verification code to reset your password."
            isSuccess = true
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to send reset link: \(error.localizedDescription)"
            isSuccess = false
            showAlert = true
        }
        
        isLoading = false
    }
    
    private func resetPassword() async {
        guard isValidReset() else {
            alertTitle = "Invalid Input"
            alertMessage = "Please ensure all fields are filled correctly and passwords match."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Verify code and reset password
            try await supabaseController.client.auth.verifyOTP(
                email: email,
                token: verificationCode,
                type: .recovery
            )
            
            try await supabaseController.client.auth.update(user: .init(password: newPassword))
            
            alertTitle = "Success"
            alertMessage = "Your password has been reset successfully. You can now log in with your new password."
            isSuccess = true
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to reset password: \(error.localizedDescription)"
            isSuccess = false
            showAlert = true
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func checkUserExists(email: String) async -> Bool {
        do {
            // Check Admin table
            let admins: [Admin] = try await supabaseController.client
                .from("Admin")
                .select()
                .eq("email", value: email)
                .execute()
                .value
            
            if !admins.isEmpty {
                return true
            }
            
            // Check Doctor table
            let doctors: [Doctor] = try await supabaseController.client
                .from("Doctor")
                .select()
                .eq("email_address", value: email)
                .execute()
                .value
            
            if !doctors.isEmpty {
                return true
            }
            
            // Check Patients table
            let patients: [Patient] = try await supabaseController.client
                .from("Patients")
                .select()
                .eq("email", value: email)
                .execute()
                .value
            
            if !patients.isEmpty {
                return true
            }
            
            // Check users table
            let users: [users] = try await supabaseController.client
                .from("users")
                .select()
                .eq("email", value: email)
                .execute()
                .value
            
            return !users.isEmpty
        } catch {
            print("Error checking user existence: \(error.localizedDescription)")
            return false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidReset() -> Bool {
        return !verificationCode.isEmpty &&
               newPassword.count >= 6 &&
               newPassword == confirmPassword
    }
    
    // MARK: - UI Components
    
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
    
    func passwordField(icon: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.mint)
            
            if isVisible.wrappedValue {
                TextField(placeholder, text: text)
                    .autocapitalization(.none)
            } else {
                SecureField(placeholder, text: text)
            }
            
            Button(action: {
                isVisible.wrappedValue.toggle()
            }) {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.mint.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ForgotPasswordView()
}
