import SwiftUI

// MARK: - Patient Signup View
struct PatientSignupView: View {
    @State private var progress: Double = 0.0
    @State private var showMedicalInfo = false
    @State private var patientDetails: Patient?
    @State private var showDashboard = false // State for Dashboard navigation

    var body: some View {
        NavigationStack {
            PersonalInfoView(
                progress: $progress,
                showMedicalInfo: $showMedicalInfo,
                patientDetails: $patientDetails
            )
            .navigationDestination(isPresented: $showMedicalInfo) {
                MedicalInfoView(
                    progress: $progress,
                    patientDetails: $patientDetails,
                    showDashboard: $showDashboard
                )
            }
            .navigationDestination(isPresented: $showDashboard) {
                PatientDashboard() // Navigate to PatientDashboard
            }
        }
    }
}

// MARK: - Personal Info View
struct PersonalInfoView: View {
    @Binding var progress: Double
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
        VStack {
            ProgressBarView(progress: progress)

            VStack(spacing: 15) {
                Text("Personal Information")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                TextField("Full Name", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.compact)

                TextField("Contact Number", text: $contactNumber)
                    .keyboardType(.phonePad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

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
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func validateAndProceed() {
        if fullName.isEmpty || gender == "Select Gender" || contactNumber.isEmpty || email.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
        } else {
            withAnimation { progress = 0.5 }
            showMedicalInfo = true
        }
    }
}

// MARK: - Medical Info View
struct MedicalInfoView: View {
    @Binding var progress: Double
    @Binding var patientDetails: Patient?
    @Binding var showDashboard: Bool // Bind to trigger Dashboard navigation

    @State private var bloodGroup = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            ProgressBarView(progress: progress)

            VStack(spacing: 15) {
                Text("Medical Information")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                TextField("Blood Group", text: $bloodGroup)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Allergies", text: $allergies)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Medical Conditions", text: $medicalConditions)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: submitDetails) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func submitDetails() {
        if bloodGroup.isEmpty || allergies.isEmpty || medicalConditions.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
        } else {
            withAnimation { progress = 1.0 }
            patientDetails = Patient(
                fullName: "Full Name Placeholder",
                gender: "Gender Placeholder",
                dateOfBirth: Date(),
                contactNumber: "Contact Placeholder",
                email: "Email Placeholder",
                bloodGroup: bloodGroup,
                allergies: allergies,
                medicalConditions: medicalConditions,
                medications: "",
                pastSurgeries: "",
                emergencyContact: ""
            )
            showDashboard = true // Navigate to Dashboard
        }
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    var progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 10)
                    .opacity(0.3)
                    .foregroundColor(.gray)

                Rectangle()
                    .frame(width: geometry.size.width * CGFloat(progress), height: 10)
                    .foregroundColor(.mint)
            }
            .cornerRadius(5)
        }
        .frame(height: 10)
    }
}

// MARK: - Preview
struct PatientSignupView_Previews: PreviewProvider {
    static var previews: some View {
        PatientSignupView()
    }
}
