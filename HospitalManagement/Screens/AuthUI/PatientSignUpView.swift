import SwiftUI

// MARK: - Patient Signup View
struct PatientSignupView: View {
    @State private var patientDetails: Patient?
    @State private var showMedicalInfo = false
    @State private var showDashboard = false
    var patient: Patient = Patient(id: UUID(), fullName: "Ram", gender: "male", dateOfBirth: Date(), phoneNumber: "1234567890", email: "ram@mail.com")

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

    @State private var fullName = ""
    @State private var gender = "Select Gender"
    @State private var dateOfBirth = Date()
    @State private var contactNumber = ""
    @State private var email = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

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

            Spacer()

            Button(action: validateAndProceed) {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mint)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func validateAndProceed() {
        if fullName.isEmpty || gender == "Select Gender" || contactNumber.isEmpty || email.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
        } else {
            showMedicalInfo = true
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
    
    var patient: Patient = Patient(id: UUID(), fullName: "Ram", gender: "male", dateOfBirth: Date(), phoneNumber: "1234567890", email: "ram@mail.com")


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
                    destination: PatientDashboard(patient: patient ),
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
            patientDetails = Patient(id: UUID(), fullName: "Your name", gender: "Not Defined", dateOfBirth: Date(), phoneNumber: "", email: "")
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
