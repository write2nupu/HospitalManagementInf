import SwiftUI

struct LoginScreen: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible = false
    @State private var isLoggedIn = false
    @State private var errorMessage: String? = nil
    @State private var selectedRole = "Patients"
    
    var roles: [String] = ["Patients", "Doctor", "Admin", "Super-Admin"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Title
                    VStack(spacing: 15) {
                        Text("Hospital Management System")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("Your Trusted Healthcare Partner")
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                    }

                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.black)
                            TextField("Email", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .padding()
                        .background(AppConfig.primaryColor)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)

                        // Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.black)
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(AppConfig.primaryColor)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)

                        // Role Picker Styled like Other Fields
                        // Role Picker Styled like Other Fields
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.black)

                            Text(selectedRole)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading) // Push text to the left

                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(AppConfig.primaryColor)
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
                        .padding(.horizontal, 40)
                        .overlay(
                            Menu {
                                Picker("Select Role", selection: $selectedRole) {
                                    ForEach(roles, id: \.self) { role in
                                        Text(role).tag(role)
                                    }
                                }
                            } label: {
                                Color.clear.frame(width: .infinity, height: 50) // Transparent Button
                            }
                        )


                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, -10)
                        }
                    }
                    .padding(.top, 20)

                    Spacer()

                    // Login Button
                    Button(action: {
                        if !isValidEmail(email) {
                            errorMessage = "Enter a valid email address"
                        } else if !isValidPassword(password) {
                            errorMessage = "Password must be alphanumeric & at least 4 characters"
                        } else {
                            errorMessage = nil
                            withAnimation {
                                isLoggedIn = true
                            }
                        }
                    }) {
                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppConfig.buttonColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)

                    Spacer()
                }
                .navigationDestination(isPresented: $isLoggedIn) {
                    forcePasswordUpdate()  // Ensure this view exists
                }
            }
        }
    }

    // Function to validate email
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    // Function to validate password
    func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = #"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{4,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
}

// Preview
#Preview {
    LoginScreen()
}
