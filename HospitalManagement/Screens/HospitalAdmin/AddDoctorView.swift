import SwiftUI
import Foundation

struct AddDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseController()
    
    // If department is passed, use it. Otherwise, allow selection
    var initialDepartment: Department?
    @State private var selectedDepartment: Department?
    @State private var departments: [Department] = []
    
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var experience = ""
    @State private var qualifications = ""
    @State private var licenseNumber = ""
    @State private var gender = "Male"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(department: Department? = nil) {
        self.initialDepartment = department
        _selectedDepartment = State(initialValue: department)
    }
    
    // Add new validation properties
    private var isPhoneNumberValid: Bool {
        phoneNumber.count == 10 && phoneNumber.allSatisfy { $0.isNumber }
    }
    
    private var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+@(gmail|yahoo|outlook)\.com$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isExperienceValid: Bool {
        guard let experienceInt = Int(experience) else { return false }
        return experienceInt > 0
    }
    
    private var isQualificationsValid: Bool {
        !qualifications.isEmpty
    }
    
    private var isLicenseNumberValid: Bool {
        !licenseNumber.isEmpty && licenseNumber.count >= 6
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        selectedDepartment != nil &&
        isPhoneNumberValid &&
        isEmailValid &&
        isExperienceValid &&
        isQualificationsValid &&
        isLicenseNumberValid
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Full Name", text: $fullName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                
                if initialDepartment == nil {
                    Picker("Department", selection: $selectedDepartment) {
                        Text("Select Department").tag(nil as Department?)
                        ForEach(departments) { department in
                            Text(department.name).tag(department as Department?)
                        }
                    }
                } else {
                    HStack {
                        Text("Department")
                        Spacer()
                        Text(initialDepartment?.name ?? "")
                            .foregroundColor(.secondary)
                    }
                }
                
                TextField("License Number", text: $licenseNumber)
                    .textContentType(.none)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
            } header: {
                Text("Personal Information")
            } footer: {
                Text("Enter a valid medical license number")
            }
            
            Section {
                HStack {
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                    
                    if !phoneNumber.isEmpty {
                        Image(systemName: isPhoneNumberValid ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(isPhoneNumberValid ? .green : .red)
                    }
                }
                
                HStack {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if !email.isEmpty {
                        Image(systemName: isEmailValid ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(isEmailValid ? .green : .red)
                    }
                }
            } header: {
                Text("Contact Information")
            }
            
            Section {
                TextField("Experience (years)", text: $experience)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                
                TextField("Qualifications (e.g., MBBS)", text: $qualifications)
                    .onChange(of: qualifications) { oldValue, newValue in
                        qualifications = newValue.uppercased()
                    }
                    .autocorrectionDisabled()
            } header: {
                Text("Professional Information")
            } footer: {
                Text("Enter professional qualifications in capital letters")
            }
        }
        .navigationTitle("Add Doctor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await saveDoctor()
                    }
                }
                .disabled(!isFormValid)
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        }
        .task {
            if initialDepartment == nil {
                if let hospitalId = getCurrentHospitalId() {
                    departments = await supabaseController.fetchHospitalDepartments(hospitalId: hospitalId)
                }
            }
        }
    }
    
    private func saveDoctor() async {
        // Use either initialDepartment or selectedDepartment
        guard let department = initialDepartment ?? selectedDepartment else {
            alertMessage = "Please select a department"
            showAlert = true
            return
        }
        
        // Generate initial password
        let initialPassword = String((0..<6).map { _ in "0123456789".randomElement()! })
        
        let newDoctor = Doctor(
            id: UUID(),
            fullName: fullName,
            departmentId: department.id,
            hospitalId: getCurrentHospitalId(),
            experience: Int(experience) ?? 0,
            qualifications: qualifications,
            isActive: true,
            isFirstLogin: true,
            initialPassword: initialPassword,
            phoneNumber: phoneNumber,
            email: email,
            gender: gender,
            licenseNumber: licenseNumber
        )
        
        do {
            try await supabaseController.client
                .from("Doctors")
                .insert(newDoctor)
                .execute()
            
            alertMessage = "Doctor added successfully"
            showAlert = true
        } catch {
            alertMessage = "Error adding doctor: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // Helper function to get current hospital ID (implement based on your auth system)
    private func getCurrentHospitalId() -> UUID? {
        // Implement this based on your authentication system
        // For example, get it from UserDefaults or your auth state
        return nil // Replace with actual implementation
    }
}
