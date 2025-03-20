import SwiftUI

struct LoginScreen: View {
    @State private var selectedSegment = 0
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToSignUp = false  // For navigation logic

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
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                        Text("Your Trusted Healthcare Partner")
                            .font(.body)
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
                        customTextField(icon: "envelope.fill", placeholder: "Enter Email", text: $email, keyboardType: .emailAddress)

                        passwordField(icon: "lock.fill", placeholder: selectedSegment == 0 ? "Enter Password" : "Create Password", text: $password)

                        if selectedSegment == 1 {
                            passwordField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword)
                        }
                    }
                    .padding(.top, 20)

                    Spacer()

                    // Submit Button
                    Button(action: handleSubmit) {
                        Text(selectedSegment == 0 ? "Login" : "Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.mint)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)

                    // Navigation Trigger
                    NavigationLink("", destination: PatientSignUpView(), isActive: $navigateToSignUp)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Action Required"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Submission Logic
    func handleSubmit() {
        if email.isEmpty || password.isEmpty || (selectedSegment == 1 && confirmPassword.isEmpty) {
            alertMessage = "Please fill in all required fields."
            showAlert = true
        } else if selectedSegment == 1 && password != confirmPassword {
            alertMessage = "Passwords do not match."
            showAlert = true
        } else if selectedSegment == 1 {
            navigateToSignUp = true  // Navigate to PatientSignUpView
        } else {
            alertMessage = "Login Successful!"
            showAlert = true
        }
    }

    // MARK: - Helper Views
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

// MARK: - Preview
struct PatientLoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
