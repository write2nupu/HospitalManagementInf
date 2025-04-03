import SwiftUI
import PostgREST
import Supabase
import Auth

struct updateFields: View {
    var doctor: Doctor
    @State private var email: String
    @State private var phone: String
    @State private var updatedEmail: String = ""
    @State private var updatePhone: String = ""
    @State private var currentPassword: String = ""
    @State private var isEditing = false
    @State private var errorMessageEmail: String? = nil
    @State private var errorMessagePhone: String? = nil
    @State private var isSaved = false
    @State private var isLoading = false
    @State private var showPasswordAlert = false
    @State private var shouldRedirectToLogin = false
    @AppStorage("isLoggedIn") private var isUserLoggedIn = false
    @StateObject private var supabaseController = SupabaseController()
    
    init(doctor: Doctor) {
        self.doctor = doctor
        _email = State(initialValue: doctor.email_address)
        _phone = State(initialValue: doctor.phone_num)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // **Email Section**
                VStack(alignment: .leading, spacing: 5) {
//                    Text("Email")
//                        .font(.headline)
                    
//                    TextField("Enter new email", text: isEditing ? $updatedEmail : $email)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding(.horizontal, 10)
//                        .disabled(!isEditing)
//                        .keyboardType(.emailAddress)
//                        .onChange(of: updatedEmail) { _ in validateEmail() }
//                    
//                    if let error = errorMessageEmail {
//                        Text(error)
//                            .foregroundColor(.red)
//                            .font(.caption)
//                            .padding(.horizontal, 10)
//                    }
                }

                // **Phone Number Section**
                VStack(alignment: .leading, spacing: 5) {
                    Text("Phone Number")
                        .font(.headline)
                    
                    TextField("Enter new phone", text: isEditing ? $updatePhone : $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 10)
                        .disabled(!isEditing)
                        .keyboardType(.numberPad)
                        .onChange(of: updatePhone) { print(validatePhone()) }
                    
                    if let error = errorMessagePhone {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 10)
                    }
                }

                // **Save Changes Button**
                Button(action: {
                    if updatedEmail != email {
                        showPasswordAlert = true
                    } else {
                        Task {
                            await saveChanges()
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave() ? AppConfig.buttonColor : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .disabled(!canSave() || isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("Update Info")
            .tint(AppConfig.fontColor)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                isEditing.toggle()
                if isEditing {
                    updatedEmail = email
                    updatePhone = phone
                }
            }) {
                Text(isEditing ? "Cancel" : "Edit")
                    .foregroundColor(AppConfig.buttonColor)
            })
            .fullScreenCover(isPresented: $shouldRedirectToLogin) {
                UserRoleScreen()
            }
            .navigationDestination(isPresented: $isSaved) {
                DoctorProfileView(doctor: doctor)
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshDoctorProfile"), object: nil)
                    }
            }
            .alert("Verify Password", isPresented: $showPasswordAlert) {
                SecureField("Enter current password", text: $currentPassword)
                Button("Cancel", role: .cancel) {
                    currentPassword = ""
                }
                Button("Update") {
                    Task {
                        await saveChangesWithPassword()
                    }
                }
            } message: {
                Text("Please enter your current password to update your email")
            }
            .alert("Email Updated", isPresented: .constant(shouldRedirectToLogin)) {
                Button("OK") {
                    // This will trigger the fullScreenCover to show login screen
                    isUserLoggedIn = false
                }
            } message: {
                Text("Your email has been updated. Please log in again with your new email.")
            }
        }
    }
    
    // MARK: - Save Changes with Password
    private func saveChangesWithPassword() async {
        guard validateEmail() && validatePhone() else { return }
        
        isLoading = true
        do {
            // First verify the current password by trying to sign in
            try await supabaseController.client.auth.signIn(
                email: email,
                password: currentPassword
            )
            
            // Then update the email in auth
            try await supabaseController.client.auth.update(
                user: UserAttributes(email: updatedEmail)
            )
            print("Updated email in auth")
            
            // Update Doctor table
            try await supabaseController.client
                .from("Doctor")
                .update([
                    "email_address": updatedEmail,
                    "phone_num": updatePhone
                ])
                .eq("id", value: doctor.id.uuidString)
                .execute()
            print("Updated Doctor table")
            
            // Update users table
            try await supabaseController.client
                .from("users")
                .update([
                    "email": updatedEmail,
                    "phone_number": updatePhone,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: doctor.id.uuidString)
                .execute()
            print("Updated users table")
            
            // Sign out and show login screen
            try await supabaseController.client.auth.signOut()
            shouldRedirectToLogin = true
            
            // Update local state
            email = updatedEmail
            phone = updatePhone
            isEditing = false
            currentPassword = ""
            
        } catch {
            print("Error updating profile:", error)
            if let authError = error as? AuthError {
                errorMessageEmail = "Auth Error: Invalid password or authentication failed"
                print(authError)
            } else if let postgrestError = error as? PostgrestError {
                errorMessageEmail = "Database Error: \(postgrestError.message)"
            } else {
                errorMessageEmail = "Failed to update: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }
    
    // MARK: - Save Changes (Phone Only)
    private func saveChanges() async {
        guard validatePhone() else { return }
        
        isLoading = true
        do {
            // Update Doctor table - only phone number
            try await supabaseController.client
                .from("Doctor")
                .update([
                    "phone_num": updatePhone
                ])
                .eq("id", value: doctor.id.uuidString)
                .execute()
            print("Updated Doctor table")
            
            // Update users table - only phone number
            try await supabaseController.client
                .from("users")
                .update([
                    "phone_number": updatePhone,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: doctor.id.uuidString)
                .execute()
            print("Updated users table")
            
            // Update local state
            phone = updatePhone
            isEditing = false
            isSaved = true
            
        } catch {
            print("Error updating profile:", error)
            if let postgrestError = error as? PostgrestError {
                errorMessagePhone = "Database Error: \(postgrestError.message)"
            } else {
                errorMessagePhone = "Failed to update: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }
    
    // MARK: - Validation Functions
    private func validateEmail() -> Bool {
        if updatedEmail.isEmpty {
            errorMessageEmail = "Email cannot be empty."
            return false
        }
        if !isValidEmail(updatedEmail) {
            errorMessageEmail = "Invalid email format."
            return false
        }
        errorMessageEmail = nil
        return true
    }
    
    private func validatePhone() -> Bool {
        if updatePhone.isEmpty {
            errorMessagePhone = "Phone number cannot be empty."
            return false
        }
        if let error = isValidPhoneNumber(updatePhone) {
            errorMessagePhone = error
            return false
        }
        errorMessagePhone = nil
        return true
    }
    
    private func canSave() -> Bool {
        return isEditing && (updatedEmail != email || updatePhone != phone) &&
               errorMessageEmail == nil && errorMessagePhone == nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> String? {
        let phoneRegex = #"^\d{10}$"#
        
        if phone.count < 10 { return "Phone number must be exactly 10 digits." }
        if phone.count > 10 { return "Phone number must be exactly 10 digits." }
        if !NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone) {
            return "Phone number must contain only digits."
        }
        return nil
    }
}


