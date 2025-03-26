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

    let genders = ["Select Gender", "Male", "Female", "Other"]
    
    private var isPhoneNumberValid: Bool {
        contactNumber.count == 10 && contactNumber.allSatisfy { $0.isNumber }
    }
    private var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+@(gmail|yahoo|outlook)\.com$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
            HStack {
                if isPasswordVisible {
                    TextField("Password", text: $password)
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

            HStack {
                if isConfirmPasswordVisible {
                    TextField("Confirm Password", text: $confirmPassword)
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

            let registeredPatient = try await supabaseController.signUpPatient(
                email: email,
                password: password,
                userData: newPatient
            )

            patientDetails = registeredPatient
            showMedicalInfo = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }

        isLoading = false
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

    @State private var bloodGroup = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

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

                Button(action: { submitDetails() }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
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

    private func submitDetails() {
        if bloodGroup.isEmpty || allergies.isEmpty || medicalConditions.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
        } else {
            patientDetails = Patient(id: UUID(), fullName: "Your name", gender: "Not Defined", dateOfBirth: Date(), contactNo: "", email: "")
            showDashboard = true
        }
    }
}

// MARK: - Preview
struct PatientSignupView_Previews: PreviewProvider {
    static var previews: some View {
        PatientSignupView()
    }
}

