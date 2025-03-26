import SwiftUI
import PhotosUI

struct AppointmentDetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    let appointment: DummyAppointment // to be changed after Fetch

    @State private var selectedImage: UIImage?
    @State private var diagnosticTests: String = ""
    @State private var medicines: [String] = []
    @State private var newMedicine: String = ""
    
    

    // Patient's Medical Information (Static) access threw id
    let bloodGroup = "O+"
    let allergies = "Peanuts, Pollen"
    let existingMedicalRecord = "Diabetes, Hypertension"
    let currentMedication = "Metformin"
    let pastSurgeries = "Appendectomy (2018)"
    let emergencyContact = "+91 9876543210"
    
    

    var body: some View {
        NavigationView {
            List {
                // **Appointment Details Section**
                Section(header: Text("Appointment Details").font(.headline)) {
                    InfoRowAppointment(label: "Patient Name", value: appointment.patientName)
                    InfoRowAppointment(label: "Appointment Type", value: appointment.visitType)
                    InfoRowAppointment(label: "Date & Time", value: appointment.dateTime)
                    InfoRowAppointment(label: "Status", value: appointment.status)
                }

                // **Patient's Medical Information**
                Section(header: Text("Patient’s Medical Information").font(.headline)) {
                    InfoRowAppointment(label: "Blood Group", value: bloodGroup)
                    InfoRowAppointment(label: "Allergies", value: allergies)
                    InfoRowAppointment(label: "Medical History", value: existingMedicalRecord)
                    InfoRowAppointment(label: "Current Medication", value: currentMedication)
                    InfoRowAppointment(label: "Past Surgeries", value: pastSurgeries)
                    InfoRowAppointment(label: "Emergency Contact", value: emergencyContact)
                }

                // **Doctor's Actions**
                
                
                
                
                
                
            }
            .navigationTitle("Appointment Details")
            .navigationBarItems(trailing: Button("Save") {
//                print("Saved Changes")
                presentationMode.wrappedValue.dismiss()  // ✅ Navigates back when clicked
            })
        }
    }

    // **Image Picker Function**
    func pickImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = UIApplication.shared.windows.first?.rootViewController as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }
}

// **Reusable Component: InfoRow**
struct InfoRowAppointment: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

// **Preview**
#Preview {
    AppointmentDetailView(appointment: DummyAppointment(patientName: "John Doe", visitType: "In Person Visit", description: "Chest pain and irregular heartbeat concerns.", dateTime: "March 22, 2025 | 2:00 pm", status: "Upcoming"))
}




