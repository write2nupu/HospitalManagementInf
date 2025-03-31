import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    let patientDetails: PatientDetails

    var body: some View {
        List {
            
            Section(header: Text("Personal Information")) {
                InfoRowPatientList(label: "Full Name", value: patient.fullname)
                InfoRowPatientList(label: "Gender", value: patient.gender)
                InfoRowPatientList(label: "Date of Birth", value: formatDate(patient.dateofbirth))
                InfoRowPatientList(label: "Blood Group", value: patientDetails.blood_group ?? "none")
            }
            
            Section(header: Text("Medical History")) {
                InfoRowPatientList(label: "Allergies", value: patientDetails.allergies ?? "none")
                InfoRowPatientList(label: "Current Medication", value: patientDetails.current_medication ?? "none")
                InfoRowPatientList(label: "Past Surgeries", value: patientDetails.past_surgeries ?? "none")
            }
            
            Section(header: Text("Contact Details")) {
                InfoRowPatientList(label: "Contact", value: patient.contactno)
                InfoRowPatientList(label: "Email", value: patient.email)
                InfoRowPatientList(label: "Emergency Contact", value: patientDetails.emergency_contact ?? "Emergency Contact")
            }
        }
        .listStyle(InsetGroupedListStyle()) // ✅ Makes it look like iOS TableView
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline) // ✅ Small title
    }

    // Helper function to format Date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Row View for Table
struct InfoRowPatientList: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.none)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}
