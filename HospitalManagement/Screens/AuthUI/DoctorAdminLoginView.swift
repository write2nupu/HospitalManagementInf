import SwiftUI

struct AdminLoginView: View {
    @State var message: String
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false // ✅ State for Navigation
    
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
                        .onChange(of: emailOrPhone) { _ in validateInputs() } // ✅ Live validation
                }

                // Password Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.gray)
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: password) { _ in validateInputs() } // ✅ Live validation
                }

                // Login Button
                Button(action: handleLogin) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid() ? Color.mint : Color.gray) // ✅ Disable if invalid
                        .cornerRadius(12)
                        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!isValid()) // ✅ Disable button when inputs are invalid
                .padding(.top, 20)

                // Navigation Trigger after Successful Login
                NavigationLink(destination: DashBoard(), isActive: $isLoggedIn) { EmptyView() }

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
        if isValid() {
            isLoggedIn = true
            print("Logged in successfully.")
        } else {
            showAlert = true
            errorMessage = "Invalid credentials. Please check your input."
        }
    }

    // MARK: - Input Validation
    private func validateInputs() {
        if emailOrPhone.isEmpty || password.isEmpty {
            errorMessage = "All fields are required."
        } else if !isValidEmailOrPhone(emailOrPhone) {
            errorMessage = "Enter a valid email or phone number."
        } else if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
        } else {
            errorMessage = ""
        }
    }

    private func isValid() -> Bool {
        return isValidEmailOrPhone(emailOrPhone) && password.count >= 6
    }

    private func isValidEmailOrPhone(_ input: String) -> Bool {
        let emailRegex = #"^\S+@\S+\.\S+$"#
        let phoneRegex = #"^\d{10}$"#
        return input.range(of: emailRegex, options: .regularExpression) != nil ||
               input.range(of: phoneRegex, options: .regularExpression) != nil
    }
}

// ✅ Preview
#Preview {
    AdminLoginView(message: "Admin")
}
