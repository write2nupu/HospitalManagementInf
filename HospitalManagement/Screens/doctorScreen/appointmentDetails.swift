import SwiftUI
import PhotosUI

struct AppointmentDetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    let appointment: Appointment // to be changed after Fetch

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
//                    InfoRowAppointment(label: "Patient Name", value: appointment.patientName)  to be fetched by patient ID
                    InfoRowAppointment(label: "Appointment Type", value: appointment.type.rawValue)
                    InfoRowAppointment(label: "Date & Time", value: formatDate(appointment.date))

                    InfoRowAppointment(label: "Status", value: appointment.status.rawValue)
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
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy - h:mm a" // Example: "Mar 26, 2025 - 10:30 AM"
        return formatter.string(from: date)
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






