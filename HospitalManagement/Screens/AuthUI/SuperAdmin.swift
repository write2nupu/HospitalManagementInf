import SwiftUI
import Supabase

struct SuperAdminLoginView: View {
    var message: String
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var shouldShowDashboard = false
    @State private var showForgotPassword = false
    @State private var showOTPVerification = false
    @State private var isEmailVerified = false
    @StateObject private var supabaseController = SupabaseController()
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @AppStorage("isLoggedIn") private var isUserLoggedIn = false
    @State private var superAdminUser: users? = nil
 
    @State private var passwordErrorMessage = ""
    @State private var emailErrorMessage = ""
  
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // App Logo
                Image("superadmin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 10)

                // Title
                Text(message)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                // Email Input
                VStack(alignment: .leading, spacing: 5) {
                    customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $email, keyboardType: .emailAddress)
                }

                // Password Input
                VStack(alignment: .leading, spacing: 5) {
                    passwordField(icon: "lock.fill", placeholder: "Enter Password", text: $password)
                }
                // Forgot Password Button
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.mint)
                }
                                .padding(.top, -15)
                                .padding(.bottom, 15)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal)
                
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
                .background(isValid() ? Color.mint : Color.gray)
                .cornerRadius(12)
                .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
                .disabled(!isValid() || isLoading)
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()
            }
            .padding()
            .background(Color.mint.opacity(0.05))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                if let user = superAdminUser {
                    forcePasswordUpdate(user: user)
                }
            }
            .navigationDestination(isPresented: $shouldShowDashboard) {
                ContentView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showOTPVerification) {
                OTPVerificationView(
                    email: email,
                    onVerificationComplete: {
                        isEmailVerified = true
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
    }

    // MARK: - Login Logic
    private func handleLogin() async {
        guard isValid() else {
            errorMessage = "Please enter valid email and password"
            showAlert = true
            return
        }

        isLoading = true
        do {
            print("Attempting to login with email:", email)
            
            // First check if user exists in Users table with super_admin role
            let superAdmins: [users] = try await supabaseController.client
                .from("users")
                .select()
                .eq("email", value: email)
                .eq("role", value: "super_admin")
                .execute()
                .value
            
            print("Found \(superAdmins.count) super admin(s) with email:", email)
            
            if let superAdmin = superAdmins.first {
                print("Found super admin in database, sending OTP")
                
                // Send OTP first and wait for verification
                try await supabaseController.sendOTP(email: email)
                showOTPVerification = true
                
            } else {
                errorMessage = "Access denied. You must be a Super Admin to login."
                showAlert = true
                isLoading = false
                print("Access denied. Email not found in Users table with super_admin role")
            }
        } catch {
            print("Error:", error.localizedDescription)
            errorMessage = "An error occurred. Please try again."
            showAlert = true
            isLoading = false
        }
    }
    
    private func completeLogin() async {
        do {
            // Only authenticate with password after OTP verification is successful
            let authResponse = try await supabaseController.client.auth.signIn(
                email: email,
                password: password
            )
            print("Authentication successful")
            
            // Get super admin details
            let superAdmins: [users] = try await supabaseController.client
                .from("users")
                .select()
                .eq("email", value: email)
                .eq("role", value: "super_admin")
                .execute()
                .value
            
            if let superAdmin = superAdmins.first {
                // Store user info
                currentUserId = authResponse.user.id.uuidString
                isUserLoggedIn = true
                UserDefaults.standard.set("super_admin", forKey: "userRole")
                
                if superAdmin.is_first_login {
                    superAdminUser = superAdmin
                    isLoggedIn = true
                } else {
                    shouldShowDashboard = true
                }
            }
        } catch {
            errorMessage = "Authentication failed. Please try again."
            showAlert = true
        }
        isLoading = false
    }

    // MARK: - Input Validation
    private func isValid() -> Bool {
        return isValidEmail(email) && isValidPassword(password)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
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
                        if placeholder == "Enter Email" {
                            if !newValue.isEmpty && !isValidEmail(newValue) {
                                emailErrorMessage = "Please enter a valid email"
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
            
            if placeholder == "Enter Email" && !emailErrorMessage.isEmpty {
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
                            if !newValue.isEmpty && !isValidPassword(newValue) {
                                passwordErrorMessage = "Password must be at least 8 characters with 1 number, 1 letter, and 1 special character"
                            } else {
                                passwordErrorMessage = ""
                            }
                        }
                } else {
                    SecureField(placeholder, text: text)
                        .onChange(of: text.wrappedValue) { oldValue, newValue in
                            if !newValue.isEmpty && !isValidPassword(newValue) {
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
            
            if !passwordErrorMessage.isEmpty {
                Text(passwordErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SuperAdminLoginView(message: "Super Admin")
}

