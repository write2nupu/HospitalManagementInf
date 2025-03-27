import SwiftUI
import Supabase

struct AdminLoginViewS: View {
    var message: String
    
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @StateObject private var supabaseController = SupabaseController()
    @State private var userAdminData: users?
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @AppStorage("isLoggedIn") private var isUserLoggedIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // **App Logo**
                Image(systemName: "building.2.fill")
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
                if let user = userAdminData {
                    if user.is_first_login {
                        forcePasswordUpdate(user: user)
                    } else {
                        AdminTabView()
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
            
            // First check if user exists in Admin table
            let admins: [Admin] = try await supabaseController.client
                .from("Admin")
                .select()
                .eq("email", value: emailOrPhone)
                .execute()
                .value
            
            print("Found \(admins.count) admin(s) with email:", emailOrPhone)
            
            if let admin = admins.first {
                print("Found admin in database, attempting authentication")
                
                // Then try to authenticate
                do {
                    let authResponse = try await supabaseController.client.auth.signIn(
                        email: emailOrPhone,
                        password: password
                    )
                    print("Authentication successful")
                    
                    // Store hospital ID in UserDefaults
                    if let hospitalId = admin.hospital_id {
                        UserDefaults.standard.set(hospitalId.uuidString, forKey: "hospitalId")
                        print("Stored hospital ID in UserDefaults:", hospitalId.uuidString)
                    } else {
                        print("Warning: Admin has no associated hospital ID")
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
                        userAdminData = existingUser
                        currentUserId = existingUser.id.uuidString
                        isUserLoggedIn = true
                        isLoggedIn = true
                        print("Found existing user, is_first_login:", existingUser.is_first_login)
                    } else {
                        // Create new user object for admin
                        let user = users(
                            id: authResponse.user.id,
                            email: admin.email,
                            full_name: admin.full_name,
                            phone_number: admin.phone_number,
                            role: "admin",
                            is_first_login: true,
                            is_active: true,
                            hospital_id: admin.hospital_id,
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
                        userAdminData = user
                        currentUserId = user.id.uuidString
                        isUserLoggedIn = true
                        isLoggedIn = true
                    }
                    print("Successfully logged in as Admin")
                } catch let authError {
                    print("Authentication error:", authError.localizedDescription)
                    errorMessage = "Invalid credentials. Please check your email and password."
                    showAlert = true
                }
            } else {
                errorMessage = "Access denied. You must be an Admin to login."
                showAlert = true
                print("Access denied. Email not found in Admin table")
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
        return isValidEmail(emailOrPhone) && password.count >= 6
    }

    private func isValidEmail(_ input: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: input)
    }
    
    // MARK: - **Helper Views**
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

// ✅ Preview
#Preview {
    AdminLoginViewS(message: "Admin")
}
