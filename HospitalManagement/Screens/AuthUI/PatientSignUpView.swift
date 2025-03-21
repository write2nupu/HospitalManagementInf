import SwiftUI

// MARK: - Patient Signup View
struct PatientSignupView: View {
    @State private var showDashboard = false
    var patient: Patient = Patient(id: UUID(), fullName: "Ram", gender: "male", dateOfBirth: Date(), phoneNumber: "1234567890", email: "ram@mail.com")

    var body: some View {
        NavigationStack {
            PersonalInfoView(showDashboard: $showDashboard, patient: patient)
                .navigationDestination(isPresented: $showDashboard) {
                    PatientDashboard(patient: patient)
                }
        }
    }
}

// MARK: - Personal Info View
struct PersonalInfoView: View {
    @Binding var showDashboard: Bool
    var patient: Patient

    @State private var fullName = ""
    @State private var gender = "Select Gender"
    @State private var dateOfBirth = Date()
    @State private var contactNumber = ""

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

            Spacer()

            Button(action: validateAndSubmit) {
                Text("Submit")
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

    private func validateAndSubmit() {
        if fullName.isEmpty || gender == "Select Gender" || contactNumber.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
        } else {
            showDashboard = true
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

// MARK: - Preview
struct PatientSignupView_Previews: PreviewProvider {
    static var previews: some View {
        PatientSignupView()
    }
}
