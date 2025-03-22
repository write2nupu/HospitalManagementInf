import SwiftUI

struct updateFields: View {
    var doctor: Doctor
    @State private var email: String
    @State private var phone: String
    @State private var updatedEmail: String = ""
    @State private var updatePhone: String = ""
    @State private var isEditing = false
    @State private var errorMessageEmail: String? = nil
    @State private var errorMessagePhone: String? = nil
    @State private var isSaved = false
    
    init(doctor: Doctor) {
        self.doctor = doctor  // ✅ Initialize doctor
        _email = State(initialValue: doctor.email_address)
        _phone = State(initialValue: doctor.phone_num)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // **Email Section**
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email")
                        .font(.headline)
                    
                    TextField("Enter new email", text: isEditing ? $updatedEmail : $email) // ✅ Use updatedEmail when editing
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 10)
                        .disabled(!isEditing)
                        .keyboardType(.emailAddress)
                        .onChange(of: updatedEmail) { _ in validateEmail() }
                    
                    if let error = errorMessageEmail {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 10)
                    }
                }

                // **Phone Number Section**
                VStack(alignment: .leading, spacing: 5) {
                    Text("Phone Number")
                        .font(.headline)
                    
                    TextField("Enter new phone", text: isEditing ? $updatePhone : $phone) // ✅ Use updatePhone when editing
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 10)
                        .disabled(!isEditing)
                        .keyboardType(.numberPad)
                        .onChange(of: updatePhone) { _ in validatePhone() }
                    
                    if let error = errorMessagePhone {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 10)
                    }
                }

                // **Save Changes Button**
                Button(action: {
                    if validateEmail() && validatePhone() {
                        // ✅ Save changes to original fields
                        email = updatedEmail
                        phone = updatePhone
                        isEditing = false
                    }
                }) {
                    Text("Save Changes")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave() ? AppConfig.buttonColor : Color.gray)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .disabled(!canSave())

                Spacer()
            }
            .padding()
            .navigationTitle("Update Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                isEditing.toggle()
                if isEditing {
                    // ✅ Pre-fill fields with existing data
                    updatedEmail = email
                    updatePhone = phone
                }
            }) {
                Text(isEditing ? "Cancel" : "Edit")
                    .foregroundColor(.blue)
            })
            .navigationDestination(isPresented: $isSaved) {
                DoctorProfileView(doctor: doctor)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    // **Validation Functions**
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


