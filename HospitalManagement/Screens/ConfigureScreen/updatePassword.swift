import SwiftUI

struct updatePassword: View {
    var doctor: Doctor
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
                   
                    
                    // Password Fields
                    VStack(spacing: 15) {
                        // New Password
                        VStack(alignment: .leading, spacing: 5) {
                            Text("New Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.black)
                                
                                if isPasswordVisible {
                                    TextField("Enter new password", text: $password)
                                } else {
                                    SecureField("Enter new password", text: $password)
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
                        }
                        .padding(.horizontal, 40)
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.black)
                                
                                if isConfirmPasswordVisible {
                                    TextField("Confirm password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm password", text: $confirmPassword)
                                }
                                
                                Button(action: {
                                    isConfirmPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(AppConfig.primaryColor)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
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
                        if password.isEmpty || confirmPassword.isEmpty {
                            errorMessage = "Please fill in both fields"
                        } else if password.count < 6 {
                            errorMessage = "Password must be at least 6 characters"
                        } else if password != confirmPassword {
                            errorMessage = "Passwords do not match"
                        } else {
                            errorMessage = nil
                            isUpdated = true
                        }
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
            .fullScreenCover(isPresented: $isUpdated) { // Full-screen navigation
                mainBoard()
                    .navigationBarBackButtonHidden(true) // Removes back button
            }
        }
    }
}


