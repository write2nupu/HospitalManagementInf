import SwiftUI

struct LoginScreen: View {
    @State private var selectedSegment = 0
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 10) {
                        Text("Hospital Management System")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("Your Trusted Healthcare Partner")
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)

                    // Segmented Control for Login/Signup
                    Picker("Mode", selection: $selectedSegment) {
                        Text("Login").tag(0)
                        Text("Signup").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Email Field
                        customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $email, keyboardType: .emailAddress)

                        // Password Field
                        passwordField(icon: "lock.fill", placeholder: "Create Password", text: $password)

                        if selectedSegment == 1 {
                            // Confirm Password for Signup
                            passwordField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword)
                        }
                    }
                    .padding(.top, 20)

                    Spacer()

                    // Submit Button
                    NavigationLink(destination: PatientSignUpView(), isActive: Binding(
                        get: { selectedSegment == 1 },
                        set: { _ in }
                    )) {
                        Button(action: handleSubmit) {
                            Text(selectedSegment == 0 ? "Login" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppConfig.buttonColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }

    func handleSubmit() {
        // Handle login if needed, no navigation logic required as NavigationLink handles signup
    }

    // MARK: - Helper Views
    func customTextField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
            TextField(placeholder, text: text)
                .autocapitalization(.none)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color.mint)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    func passwordField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
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
        .background(Color.mint)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct PatientLoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
