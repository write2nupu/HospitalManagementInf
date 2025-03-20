import SwiftUI

struct PatientSignupView: View {
    @State private var progress: Double = 0.0
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            PersonalInfoView(progress: $progress, path: $path)
                .navigationDestination(for: String.self) { destination in
                    if destination == "MedicalInfo" {
                        MedicalInfoView(progress: $progress, path: $path)
                    } else if destination == "HospitalListView" {
                        HospitalListView()
                    }
                }
        }
    }
}

// MARK: - Personal Info View
struct PersonalInfoView: View {
    @Binding var progress: Double
    @Binding var path: [String]

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

                CustomTextField(placeholder: "Full Name", text: $fullName)
                genderSelection
                dobSelection
                CustomTextField(placeholder: "Contact Number", text: $contactNumber, keyboardType: .phonePad)
                CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress)

                Button(action: validateAndProceed) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 15)
                }
            }
            .padding()

            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Helper Views
    private var genderSelection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Gender").font(.headline)
            Menu {
                ForEach(genders, id: \.self) { gender in
                    Button(gender) { self.gender = gender }
                }
            } label: {
                HStack {
                    Text(gender)
                        .foregroundColor(gender == "Select Gender" ? .gray : .black)
                    Spacer()
                    Image(systemName: "chevron.down").foregroundColor(.gray)
                }
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(10)
            }
        }
    }

    private var dobSelection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Date of Birth").font(.headline)
            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                .datePickerStyle(.compact)
                .frame(height: 48)
                .padding(.horizontal)
                .background(Color.mint.opacity(0.2))
                .cornerRadius(10)
        }
    }

    // MARK: - Validation Logic
    private func validateAndProceed() {
        if fullName.isEmpty || gender == "Select Gender" || contactNumber.isEmpty || email.isEmpty {
            alertMessage = "Please fill in all required fields."
            showAlert = true
        } else {
            withAnimation { progress = 0.5 }
            path.append("MedicalInfo")
        }
    }
}

// MARK: - Medical Info View
struct MedicalInfoView: View {
    @Binding var progress: Double
    @Binding var path: [String]

    @State private var bloodGroup = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""
    @State private var medications = ""
    @State private var pastSurgeries = ""
    @State private var emergencyContact = ""

    var body: some View {
        VStack {
            ProgressBarView(progress: progress)

            VStack(spacing: 15) {
                Text("Medical Information")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                CustomTextField(placeholder: "Blood Group", text: $bloodGroup)
                CustomTextField(placeholder: "Allergies (if any)", text: $allergies)
                CustomTextField(placeholder: "Existing Medical Conditions", text: $medicalConditions)
                CustomTextField(placeholder: "Current Medications", text: $medications)
                CustomTextField(placeholder: "Past Surgeries/Procedures", text: $pastSurgeries)
                CustomTextField(placeholder: "Emergency Contact", text: $emergencyContact, keyboardType: .phonePad)

                Button(action: {
                    withAnimation { progress = 1.0 }
                    path.append("HospitalListView")
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 15)
                }
            }
            .padding()

            Spacer()
        }
    }
}

// MARK: - Progress Bar
struct ProgressBarView: View {
    var progress: Double

    var body: some View {
        ProgressView(value: progress, total: 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: .mint))
            .padding(.top, 20)
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.5), value: progress)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(placeholder).font(.headline)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(Color.mint.opacity(0.2))
                .cornerRadius(10)
        }
    }
}

// MARK: - Preview
struct PatientSignupView_Previews: PreviewProvider {
    static var previews: some View {
        PatientSignupView()
    }
}
