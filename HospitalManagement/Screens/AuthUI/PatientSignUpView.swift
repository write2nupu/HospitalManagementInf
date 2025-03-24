import SwiftUI

// MARK: - Patient Signup View
struct PatientSignupView: View {
    @State private var patientDetails: Patient?
    @State private var showMedicalInfo = false
    @State private var showDashboard = false
    var patient: Patient = Patient(id: UUID(), fullName: "Ram", gender: "male", dateOfBirth: Date(), contactNo: "1234567890", email: "ram@mail.com")

    var body: some View {
        NavigationStack {
            PersonalInfoView(showMedicalInfo: $showMedicalInfo, patientDetails: $patientDetails)
                .navigationDestination(isPresented: $showMedicalInfo) {
                    MedicalInfoView(patientDetails: $patientDetails, showDashboard: showDashboard)
                }
                .navigationDestination(isPresented: $showDashboard) {
                    PatientDashboard(patient: patient )
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

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    let genders = ["Select Gender", "Male", "Female", "Other"]

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

            DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(8)

            TextField("Contact Number", text: $contactNumber)
                .keyboardType(.phonePad)
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(8)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(8)
                
            // Password fields
            if isPasswordVisible {
                TextField("Password", text: $password)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)
                
                TextField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)
            } else {
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Button(action: { isPasswordVisible.toggle() }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
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
                ForEach(genders, id: \ .self) { gender in
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
import SwiftUI

struct MedicalInfoView: View {
    @Binding var patientDetails: Patient?
    @State var showDashboard: Bool = false

    @State private var bloodGroup = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""

    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var patient: Patient = Patient(id: UUID(), fullName: "Ram", gender: "male", dateOfBirth: Date(), contactNo: "1234567890", email: "ram@mail.com")


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

                // Navigation trigger
                NavigationLink(
                    destination: PatientLoginSignupView(),
                    isActive: $showDashboard
                ) {
                    EmptyView()
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
