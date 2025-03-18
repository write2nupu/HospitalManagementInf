import SwiftUI

struct LoginScreen: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible = false
    @State private var isLoggedIn = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {  // Changed to NavigationStack
            ZStack {
                // To ignore safe Area
                AppConfig.backgroundColor
                    .ignoresSafeArea()
                // to show VStack so that it can cantain everything
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
                                    .textFieldStyle(PlainTextFieldStyle())
                            } else {
                                SecureField("Password", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
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

                        // Error Message using Clouser
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

    // Function to validate email must be email
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    // Function to validate password must be aphanumeric and greater or equal to 4
    func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = #"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{4,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
}



// Preview
#Preview {
    LoginScreen()
}
