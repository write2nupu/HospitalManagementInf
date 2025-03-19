import SwiftUI

// MARK: - Patient Model
struct Patient {
    var name: String
    var dob: Date
    var contactNumber: String
    var email: String
    var bloodGroup: String?
    var allergies: String?
    var medicalConditions: String?
    var medications: String?
    var pastSurgeries: String?
    var emergencyContact: String
}

// MARK: - Patient Dashboard View
struct PatientDashboard: View {
    @State private var patient = Patient(
        name: "Shivani Verma",
        dob: Calendar.current.date(byAdding: .year, value: -22, to: Date()) ?? Date(),
        contactNumber: "+91 9876543210",
        email: "shivani.verma@example.com",
        bloodGroup: "O+",
        allergies: "None",
        medicalConditions: "Asthma",
        medications: "Inhaler",
        pastSurgeries: "Appendix Surgery (2018)",
        emergencyContact: "Ravi Verma - +91 9876543211"
    )
    
    @State private var isEditing = false
    @State private var updatedPatient: Patient
    
    init() {
        let defaultPatient = Patient(
            name: "Shivani Verma",
            dob: Calendar.current.date(byAdding: .year, value: -22, to: Date()) ?? Date(),
            contactNumber: "+91 9876543210",
            email: "shivani.verma@example.com",
            bloodGroup: "O+",
            allergies: "None",
            medicalConditions: "Asthma",
            medications: "Inhaler",
            pastSurgeries: "Appendix Surgery (2018)",
            emergencyContact: "Ravi Verma - +91 9876543211"
        )
        _updatedPatient = State(initialValue: defaultPatient)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Personal Details Section
                    EditableSection(
                        title: "👤 Personal Details",
                        isEditing: $isEditing
                    ) {
                        EditableInfoRow(title: "Name", value: $updatedPatient.name)
                        
                        HStack {
                            Text("DOB:")
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)
                            Spacer()
                            if isEditing {
                                DatePicker("", selection: $updatedPatient.dob, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            } else {
                                Text(updatedPatient.dob.formatted(date: .long, time: .omitted))
                            }
                        }
                        .padding(.vertical, 2)

                        EditableInfoRow(title: "Age", value: .constant("\(calculateAge(from: updatedPatient.dob)) years"))
                        EditableInfoRow(title: "Contact", value: $updatedPatient.contactNumber)
                        EditableInfoRow(title: "Email", value: $updatedPatient.email)
                    }
                    
                    // MARK: - Medical Information Section
                    EditableSection(
                        title: "🩺 Medical Information",
                        isEditing: $isEditing
                    ) {
                        EditableInfoRow(title: "Blood Group", value: .constant(patient.bloodGroup ?? "N/A"))
                        EditableInfoRow(title: "Allergies", value: .constant(patient.allergies ?? "None"))
                        EditableInfoRow(title: "Medical Conditions", value: .constant(patient.medicalConditions ?? "None"))
                        EditableInfoRow(title: "Medications", value: .constant(patient.medications ?? "None"))
                        EditableInfoRow(title: "Past Surgeries", value: .constant(patient.pastSurgeries ?? "None"))
                    }

                    // MARK: - Emergency Contact Section
                    EditableSection(
                        title: "🚨 Emergency Contact",
                        isEditing: $isEditing
                    ) {
                        EditableInfoRow(title: "Contact", value: $updatedPatient.emergencyContact)
                    }

                    // MARK: - Save/Cancel Buttons
                    if isEditing {
                        HStack {
                            Button("Cancel") {
                                updatedPatient = patient // Reset changes
                                isEditing.toggle()
                            }
                            .foregroundColor(.red)
                            
                            Spacer()
                            
                            Button("Save") {
                                patient = updatedPatient // Save changes
                                isEditing.toggle()
                            }
                            .foregroundColor(.mint)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Patient Dashboard")
            .toolbar {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
                .foregroundColor(.mint)
            }
        }
    }

    // MARK: - Age Calculation
    func calculateAge(from dob: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year ?? 0
    }
}

// MARK: - Editable Section Component
struct EditableSection<Content: View>: View {
    let title: String
    @Binding var isEditing: Bool
    let content: Content

    init(title: String, isEditing: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isEditing = isEditing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.mint)
            Divider().background(Color.mint)
            content
        }
        .padding()
        .background(Color.mint.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Editable Info Row
struct EditableInfoRow: View {
    let title: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text("\(title):")
                .fontWeight(.semibold)
                .foregroundColor(.mint)
            Spacer()
            TextField(title, text: $value)
                .multilineTextAlignment(.trailing)
                .disabled(false)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct PatientDashboard_Previews: PreviewProvider {
    static var previews: some View {
        PatientDashboard()
    }
}
