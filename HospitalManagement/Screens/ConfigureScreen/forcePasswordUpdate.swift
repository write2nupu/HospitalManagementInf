import SwiftUI
import PostgREST

struct forcePasswordUpdate: View {
    
    var user: users  // Accept User Data
    @Environment(\.dismiss) private var dismiss
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isUpdated = false
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @StateObject private var supabaseController = SupabaseController()
    @StateObject private var viewModel = HospitalManagementViewModel()
    
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
                        Task {
                            await validateAndUpdatePassword()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Update Password")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConfig.buttonColor)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                    .disabled(password.isEmpty || confirmPassword.isEmpty || isLoading)
                    .opacity(password.isEmpty || confirmPassword.isEmpty ? 0.6 : 1)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $isUpdated) {
                getDashboardView()
            }
        }
    }
    
    // ✅ Function to Validate Password
    private func validateAndUpdatePassword() async {
        if password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Please fill in both fields"
            return
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        do {
            print("Attempting to update password for user:", user.id.uuidString)
            print("User role:", user.role)
            
            // First update the password
            try await supabaseController.client.auth.update(user: .init(password: password))
            print("Password updated successfully in auth")
            
            // Then update is_first_login flag in the appropriate table based on role
            if user.role.lowercased().contains("super") && user.role.lowercased().contains("admin") {
                try await supabaseController.client
                    .from("Users")
                    .update(["is_first_login": false])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                print("Updated is_first_login in Users table")
            } else if user.role.lowercased().contains("admin") {
                // Update Admin table
                try await supabaseController.client
                    .from("Admin")
                    .update(["is_first_login": false])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                print("Updated is_first_login in Admin table")
                
                // Also update users table
                try await supabaseController.client
                    .from("users")
                    .update(["is_first_login": false])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                print("Updated is_first_login in users table")
            } else if user.role.lowercased().contains("doctor") {
                // Update Doctor table
                try await supabaseController.client
                    .from("Doctor")
                    .update(["is_first_login": false])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                print("Updated is_first_login in Doctor table")
                
                // Also update users table
                try await supabaseController.client
                    .from("users")
                    .update(["is_first_login": false])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                print("Updated is_first_login in users table")
            }
            
            errorMessage = nil
            isUpdated = true
        } catch {
            print("Error updating password:", error)
            if let postgrestError = error as? PostgrestError {
                print("Postgrest error details:", postgrestError)
            }
            errorMessage = "Failed to update password: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // ✅ Function to Determine Dashboard
    @ViewBuilder
    private func getDashboardView() -> some View {
        if user.role.lowercased().contains("super") && user.role.lowercased().contains("admin") {
            ContentView()
                .navigationBarBackButtonHidden(true)
        } else if user.role.lowercased().contains("admin") {
            AdminTabView()
                .environmentObject(viewModel)
                .navigationBarBackButtonHidden(true)
        } else if user.role.lowercased().contains("doctor") {
            mainBoard()
                .navigationBarBackButtonHidden(true)
        } else {
            Text("Role not recognized").foregroundColor(.red)
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


