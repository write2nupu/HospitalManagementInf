import SwiftUI

struct AdminLoginViewS: View {
    var message: String
    
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var isPasswordVisible = false
    
    @State private var userAdminData: AuthData? // ✅ Store user data dynamically

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // **App Logo**
                Image(systemName: "building.columns.fill")
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
                Button(action: handleLogin) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid() ? Color.mint : Color.gray)
                        .cornerRadius(12)
                        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!isValid())
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
                    forcePasswordUpdate(user: user)
                }
            }
        }
    }

    // MARK: - **Login Logic**
    private func handleLogin() {
        if isValid() {
            userAdminData = AuthData(role: "admin") // Set actual user data
            isLoggedIn = true
            print("Admin Logged in successfully.")
        } else {
            showAlert = true
            errorMessage = "Invalid credentials. Please check your input."
        }
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
