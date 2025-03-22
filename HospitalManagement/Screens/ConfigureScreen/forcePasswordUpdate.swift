import SwiftUI

struct forcePasswordUpdate: View {
    
    var user: User  // Accept User Data
    
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isUpdated = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    // Header
                    Spacer()
                    Text("Update Password")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("For security reasons, update your password before accessing your account.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Password Fields
                    VStack(spacing: 15) {
                        PasswordField(title: "New Password", text: $password, isVisible: $isPasswordVisible)
                        PasswordField(title: "Confirm Password", text: $confirmPassword, isVisible: $isConfirmPasswordVisible)
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, -10)
                    }
                    
                    // Update Password Button
                    Button(action: {
                        validateAndUpdatePassword()
                    }) {
                        Text("Update Password")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppConfig.buttonColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .disabled(password.isEmpty || confirmPassword.isEmpty)
                    .opacity(password.isEmpty || confirmPassword.isEmpty ? 0.6 : 1)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            // ✅ Corrected Navigation
            .navigationDestination(isPresented: $isUpdated) {
                getDashboardView()
            }
        }
    }
    
    // ✅ Function to Validate Password
    private func validateAndUpdatePassword() {
        if password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Please fill in both fields"
        } else if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
        } else if password != confirmPassword {
            errorMessage = "Passwords do not match"
        } else {
            errorMessage = nil
            isUpdated = true // ✅ Trigger Navigation
        }
    }
    
    // ✅ Function to Determine Dashboard
    @ViewBuilder
    private func getDashboardView() -> some View {
//        switch user.role.lowercased() {
//        case "admin":
//            AdminHomeView()
//        case "superadmin":
//            ContentView()
//        case "doctor":
//            mainBoard()
//        default:
//            Text("Role not recognized").foregroundColor(.red)
//        }
        
        if user.role.lowercased() == "admin" {
            AdminHomeView()
        } else if user.role.lowercased() == "superadmin" {
            ContentView()
        } else if user.role.lowercased() == "doctor"{
            mainBoard()
        }
    }
}

// ✅ Reusable Password Field Component
struct PasswordField: View {
    var title: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.black)
                
                if isVisible {
                    TextField(title, text: $text)
                } else {
                    SecureField(title, text: $text)
                }
                
                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(AppConfig.primaryColor)
            .cornerRadius(12)
        }
        .padding(.horizontal, 40)
    }
}


