import SwiftUI

struct DoctorLoginView: View {
    var message: String
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false // ✅ State for Navigation
    @State private var isPasswordVisible = false // ✅ Toggle password visibility
    @State private var isLoading = false
    @StateObject private var supabaseController = SupabaseController()
    @State private var doctorUser: users? = nil
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @AppStorage("isLoggedIn") private var isUserLoggedIn = false
    @State private var passwordErrorMessage = ""
    @State private var emailErrorMessage = ""
    
//    doctor to be deleted when Superbase function get integrated
    

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // **App Logo**
                Image(systemName: "stethoscope")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.mint)
                    .padding(.bottom, 10)

                // **Title**
                Text(message)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                // **Email/Phone Input**
                VStack(alignment: .leading, spacing: 5) {
                    customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $emailOrPhone, keyboardType: .emailAddress)
                }

                // **Password Input**
                VStack(alignment: .leading, spacing: 5) {
                    passwordField(icon: "lock.fill", placeholder: "Enter Password", text: $password)
                }

                // **Login Button**
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
            // ✅ Navigation only triggers when isLoggedIn becomes true
            .navigationDestination(isPresented: $isLoggedIn) {
                if let user = doctorUser {
                    if user.is_first_login {
                        forcePasswordUpdate(user: user)
                    } else {
                        mainBoard()
                    }
                }
            }
        }
    }

    // MARK: - **Login Logic**
    private func handleLogin() async {
        guard isValid() else {
            errorMessage = "Please enter valid email and password"
            showAlert = true
            return
        }

        isLoading = true
        do {
            print("Attempting to login with email:", emailOrPhone)
            
            // First check if user exists in Doctor table
            let doctors: [Doctor] = try await supabaseController.client
                .from("Doctor")
                .select()
                .eq("email_address", value: emailOrPhone)
                .execute()
                .value
            
            print("Found \(doctors.count) doctor(s) with email:", emailOrPhone)
            
            if let doctor = doctors.first {
                print("Found doctor in database, attempting authentication")
                
                // Then try to authenticate
                do {
                    let authResponse = try await supabaseController.client.auth.signIn(
                        email: emailOrPhone,
                        password: password
                    )
                    print("Authentication successful")
                    
                    // Store hospital and department IDs in UserDefaults
                    if let hospitalId = doctor.hospital_id {
                        UserDefaults.standard.set(hospitalId.uuidString, forKey: "hospitalId")
                        print("Stored hospital ID in UserDefaults:", hospitalId.uuidString)
                    }
                    if let departmentId = doctor.department_id {
                        UserDefaults.standard.set(departmentId.uuidString, forKey: "departmentId")
                        print("Stored department ID in UserDefaults:", departmentId.uuidString)
                    }
                    
                    // Check users table for existing user
                    let existingUsers: [users] = try await supabaseController.client
                        .from("users")
                        .select()
                        .eq("id", value: authResponse.user.id.uuidString)
                        .execute()
                        .value
                    
                    if let existingUser = existingUsers.first {
                        // Use existing user's data
                        doctorUser = existingUser
                        currentUserId = existingUser.id.uuidString
                        isUserLoggedIn = true
                        isLoggedIn = true
                        print("Found existing user, is_first_login:", existingUser.is_first_login)
                    } else {
                        // Create new user object for doctor
                        let user = users(
                            id: authResponse.user.id,
                            email: doctor.email_address,
                            full_name: doctor.full_name,
                            phone_number: doctor.phone_num,
                            role: "doctor",
                            is_first_login: true,
                            is_active: doctor.is_active,
                            hospital_id: doctor.hospital_id,
                            created_at: ISO8601DateFormatter().string(from: Date()),
                            updated_at: ISO8601DateFormatter().string(from: Date())
                        )
                        
                        // Create new user in users table
                        try await supabaseController.client
                            .from("users")
                            .insert(user)
                            .execute()
                        print("Created new user record in users table")
                        
                        // Store user info
                        doctorUser = user
                        currentUserId = user.id.uuidString
                        isUserLoggedIn = true
                        isLoggedIn = true
                    }
                    print("Successfully logged in as Doctor")
                } catch let authError {
                    print("Authentication error:", authError.localizedDescription)
                    errorMessage = "Invalid credentials. Please check your email and password."
                    showAlert = true
                }
            } else {
                errorMessage = "Access denied. You must be a Doctor to login."
                showAlert = true
                print("Access denied. Email not found in Doctor table")
            }
        } catch let dbError {
            print("Database error:", dbError.localizedDescription)
            errorMessage = "An error occurred. Please try again."
            showAlert = true
        }
        isLoading = false
    }

    // MARK: - **Input Validation**
    private func isValid() -> Bool {
        return isValidEmail(emailOrPhone) && isValidPassword(password)
    }

    private func isValidEmail(_ input: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: input)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // Basic validation: at least 8 characters with 1 number, 1 letter, and 1 special character
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
    
    // MARK: - **Helper Views**
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

