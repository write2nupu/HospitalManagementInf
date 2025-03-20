import SwiftUI

struct updateFields: View {
    var fieldName: String
    var initialValue: String
    @State private var fieldValue: String
    @State private var errorMessage: String? = nil // Stores validation error message
    @State private var isSaved = false
    
    init(fieldName: String, initialValue: String) {
        self.fieldName = fieldName
        self.initialValue = initialValue
        _fieldValue = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // TextField for Email / Phone Number
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Enter new \(fieldName)", text: $fieldValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                        .keyboardType(fieldName == "Phone" ? .numberPad : .emailAddress)
                        .onChange(of: fieldValue) { _ in
                            validateInput() // Validate when user types
                        }

                    // Show error message in red if validation fails
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 20)
                    }
                }

                // Save Changes Button
                Button(action: {
                        if validateInput() {
                            isSaved = true
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
                .disabled(!canSave()) // Disable if validation fails or no edit

                Spacer()
            }
            .navigationTitle("Update \(fieldName)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isSaved) {
                DoctorProfileView()
                    .navigationBarBackButtonHidden(true) // Hide back button after saving
            }
        }
    }
    
    // Validate Input and Store Error Message
    private func validateInput() -> Bool {
        if fieldValue.isEmpty {
            errorMessage = "\(fieldName) cannot be empty."
            return false
        }
        if fieldName == "Email", !isValidEmail(fieldValue) {
            errorMessage = "Invalid email format."
            return false
        }
        if fieldName == "Phone", let error = isValidPhoneNumber(fieldValue) {
            errorMessage = error
            return false
        }
        errorMessage = nil
        return true
    }
    
    // Disable Save Button if No Change or Error
    private func canSave() -> Bool {
        return fieldValue != initialValue && errorMessage == nil
    }
    
    // Email Validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    // Phone Number Validation
    private func isValidPhoneNumber(_ phone: String) -> String? {
        let phoneRegex = #"^\d{10}$"#
        
        if phone.isEmpty { return "Phone number cannot be empty." }
        if phone.count < 10 { return "Phone number is too short. It must be 10 digits." }
        if phone.count > 10 { return "Phone number is too long. It must be exactly 10 digits." }
        if !NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone) {
            return "Phone number must contain only digits."
        }
        return nil // No error
    }
}

// Preview
#Preview {
    NavigationStack {
        updateFields(fieldName: "Email", initialValue: "doctor@example.com")
    }
}
