import SwiftUI

// MARK: - Patient Signup View
struct PatientSignupView: View {
    @State private var patientDetails: Patient?
    @State private var showMedicalInfo = false
    @State private var showDashboard = false

    var body: some View {
        NavigationStack {
            PersonalInfoView(showMedicalInfo: $showMedicalInfo, patientDetails: $patientDetails)
                .navigationDestination(isPresented: $showMedicalInfo) {
                    MedicalInfoView(patientDetails: $patientDetails, showDashboard: showDashboard)
                }
        }
    }
}

// MARK: - Personal Info View
struct PersonalInfoView: View {
    @Binding var showMedicalInfo: Bool
    @Binding var patientDetails: Patient?
    @StateObject private var supabaseController = SupabaseController()

    @State private var fullName = ""
    @State private var gender = "Select Gender"
    @State private var dateOfBirth = Date()
    @State private var contactNumber = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var passwordErrorMessage = ""
    @State private var confirmPasswordErrorMessage = ""
    @State private var showOTPVerification = false
    @State private var tempPatient: Patient?

    let genders = ["Select Gender", "Male", "Female", "Other"]
    
    private var isPhoneNumberValid: Bool {
        contactNumber.count == 10 && contactNumber.allSatisfy { $0.isNumber }
    }
    
    private var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private var isPasswordValid: Bool {
        // At least 8 characters
        guard password.count >= 8 else { return false }
        
        // At least one numeric character
        let numberRegex = ".*[0-9]+.*"
        let numberPredicate = NSPredicate(format:"SELF MATCHES %@", numberRegex)
        guard numberPredicate.evaluate(with: password) else { return false }
        
        // At least one alphabetic character
        let letterRegex = ".*[a-zA-Z]+.*"
        let letterPredicate = NSPredicate(format:"SELF MATCHES %@", letterRegex)
        guard letterPredicate.evaluate(with: password) else { return false }
        
        // At least one special character
        let specialCharRegex = ".*[^A-Za-z0-9].*"
        let specialCharPredicate = NSPredicate(format:"SELF MATCHES %@", specialCharRegex)
        guard specialCharPredicate.evaluate(with: password) else { return false }
        
        return true
    }
    
    private var isConfirmPasswordValid: Bool {
        confirmPassword == password
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Personal Information")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.mint)

            TextField("Full Name", text: $fullName)
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(8)

            GenderPickerView(gender: $gender, genders: genders)

            DatePicker("Date of Birth", selection: $dateOfBirth, in: ...Calendar.current.date(byAdding: .day, value: -1, to: Date())!, displayedComponents: .date)
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(8)

            HStack {
                TextField("Contact Number", text: $contactNumber)
                    .keyboardType(.phonePad)
                    .padding(.trailing, 30) // Space for the icon
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        Group {
                            if !contactNumber.isEmpty {
                                Image(systemName: isPhoneNumberValid ? "checkmark.circle.fill" : "x.circle.fill")
                                    .foregroundColor(isPhoneNumberValid ? .green : .red)
                                    .padding(.trailing, 8)
                                    .offset(x: -5) // Adjust position if needed
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    )
            }

            
            HStack {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .padding(.trailing, 30) // Space for the icon
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        Group {
                            if !email.isEmpty {
                                Image(systemName: isEmailValid ? "checkmark.circle.fill" : "x.circle.fill")
                                    .foregroundColor(isEmailValid ? .green : .red)
                                    .padding(.trailing, 8)
                                    .offset(x: -5) // Adjust position if needed
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    )
            }

            // Password fields with independent eye buttons
            VStack(alignment: .leading) {
                HStack {
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .autocapitalization(.none)
                    } else {
                        SecureField("Password", text: $password)
                    }
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(8)
                
                if !password.isEmpty && !isPasswordValid {
                    Text("Password must be at least 8 characters with 1 number, 1 letter, and 1 special character")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }

            VStack(alignment: .leading) {
                HStack {
                    if isConfirmPasswordVisible {
                        TextField("Confirm Password", text: $confirmPassword)
                            .autocapitalization(.none)
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                    }
                    Button(action: { isConfirmPasswordVisible.toggle() }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(8)
                
                if !confirmPassword.isEmpty && !isConfirmPasswordValid {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }

            Spacer()

            Button(action: {
                Task {
                    await validateAndProceed()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading)
        }
        .padding()
        .sheet(isPresented: $showOTPVerification) {
            if let patient = tempPatient {
                OTPVerificationView(
                    email: patient.email,
                    onVerificationComplete: {
                        patientDetails = patient
                        showMedicalInfo = true
                        isLoading = false
                    },
                    onCancel: {
                        // Delete the created user since verification was cancelled
                        Task {
                            if let patientId = tempPatient?.id {
                                try? await supabaseController.client
                                    .from("Patient")
                                    .delete()
                                    .eq("id", value: patientId.uuidString)
                                    .execute()
                            }
                        }
                        tempPatient = nil
                        isLoading = false
                    }
                )
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func validateAndProceed() async {
        if fullName.isEmpty || gender == "Select Gender" || contactNumber.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            return
        }

        if !isEmailValid {
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }

        if !isPhoneNumberValid {
            alertMessage = "Please enter a valid 10-digit phone number."
            showAlert = true
            return
        }

        if !isPasswordValid {
            alertMessage = "Password must be at least 8 characters with 1 number, 1 letter, and 1 special character."
            showAlert = true
            return
        }

        if password != confirmPassword {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }

        isLoading = true

        do {
            let newPatient = Patient(
                id: UUID(),
                fullName: fullName,
                gender: gender.lowercased(),
                dateOfBirth: dateOfBirth,
                contactNo: contactNumber,
                email: email
            )

            // First create the patient record
            let registeredPatient = try await supabaseController.signUpPatient(
                email: email,
                password: password,
                userData: newPatient
            )
            
            // Store temporarily and show OTP verification
            tempPatient = registeredPatient
            
            // Send OTP
            try await supabaseController.sendOTP(email: email)
            showOTPVerification = true
            
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
            isLoading = false
        }
    }
}

// MARK: - Gender Picker View
struct GenderPickerView: View {
    @Binding var gender: String
    let genders: [String]

    var body: some View {
        HStack {
            Text("Gender")
                .foregroundColor(.black)
            Spacer()
            Picker("Gender", selection: $gender) {
                ForEach(genders, id: \.self) { gender in
                    Text(gender).foregroundColor(.black)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.black)
        }
        .padding()
        .background(Color.mint.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Medical Info View
struct MedicalInfoView: View {
    @Binding var patientDetails: Patient?
    @State var showDashboard: Bool = false
    @StateObject private var supabaseController = SupabaseController()

    @State private var bloodGroup = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Medical Information")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                TextField("Blood Group", text: $bloodGroup)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)

                TextField("Allergies", text: $allergies)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)

                TextField("Medical Conditions", text: $medicalConditions)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)

                Spacer()

                Button(action: { 
                    isLoading = true
                    Task {
                        await submitDetails()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mint)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    } else {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mint)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(isLoading)
                .navigationDestination(isPresented: $showDashboard) {
                    PatientLoginSignupView()
                }
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func submitDetails() async {
        if bloodGroup.isEmpty || allergies.isEmpty || medicalConditions.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            isLoading = false
            return
        }
        
        guard let patient = patientDetails else {
            alertMessage = "Patient information is missing."
            showAlert = true
            isLoading = false
            return
        }
        
        do {
            // Create patient details record
            let patientDetailsId = UUID()
            let details = PatientDetails(
                id: patientDetailsId,
                blood_group: bloodGroup,
                allergies: allergies,
                existing_medical_record: medicalConditions,
                current_medication: nil,
                past_surgeries: nil,
                emergency_contact: nil
            )
            
            // Save patient details record
            try await supabaseController.client
                .from("Patientdetails")
                .insert(details)
                .execute()
            
            print("✅ Patient details saved with ID: \(patientDetailsId)")
            
            // Update patient record with detail_id
            var updatedPatient = patient
            updatedPatient.detail_id = patientDetailsId
            
            try await supabaseController.client
                .from("Patient")
                .update(["detail_id": patientDetailsId])
                .eq("id", value: patient.id.uuidString)
                .execute()
            
            print("✅ Patient record updated with detail_id: \(patientDetailsId)")
            
            // Set persistence values in UserDefaults
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(patient.id.uuidString, forKey: "currentUserId")
            UserDefaults.standard.set("patient", forKey: "userRole")
            UserDefaults.standard.set(patient.id.uuidString, forKey: "currentPatientId")
            
            print("✅ Patient login persisted in UserDefaults - ID: \(patient.id.uuidString)")
            
            await MainActor.run {
                isLoading = false
                showDashboard = true
            }
        } catch {
            print("❌ Error saving patient details: \(error)")
            await MainActor.run {
                alertMessage = "Failed to save medical information: \(error.localizedDescription)"
                showAlert = true
                isLoading = false
            }
        }
    }
}

// MARK: - Preview
struct PatientSignupView_Previews: PreviewProvider {
    static var previews: some View {
        PatientSignupView()
    }
}
