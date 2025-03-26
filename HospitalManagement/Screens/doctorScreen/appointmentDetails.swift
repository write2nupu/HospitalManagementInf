import SwiftUI
import PhotosUI

struct AppointmentDetailView: View {
    let appointment: DummyAppointment

    @State private var selectedImage: UIImage?
    @State private var diagnosticTests: String = ""
    @State private var medicines: [String] = []
    @State private var newMedicine: String = ""
    
    @Environment(\.presentationMode) var presentationMode

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
                Section(header: Text("Doctor’s Actions").font(.headline)) {
                    
                    // **Prescription Upload**
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upload Prescription Photo")
                            .font(.subheadline)
                            .bold()

                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                                .shadow(radius: 4)
                        }

                        Button(action: pickImage) {
                            Label("Upload Image", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.vertical, 8)

                    // **Prescribed Medicines Entry**
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Prescribed Medicines")
                            .font(.subheadline)
                            .bold()

                        HStack {
                            TextField("Enter medicine name", text: $newMedicine)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button(action: {
                                if !newMedicine.isEmpty {
                                    medicines.append(newMedicine)
                                    newMedicine = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }

                        if !medicines.isEmpty {
                            ForEach(medicines, id: \.self) { medicine in
                                Text("• \(medicine)")
                                    .font(.body)
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    // **Diagnostic Tests Recommendation**
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommend Diagnostic Tests")
                            .font(.subheadline)
                            .bold()

                        TextEditor(text: $diagnosticTests)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .shadow(radius: 3)
                    }
                    .padding(.vertical, 8)
                }
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
