import SwiftUI
import PhotosUI
import PDFKit

// Add this structure for prescription data
struct PrescriptionData {
    let id: String
    let date: String
    let doctorName: String
    let doctorQualification: String
    let doctorRegNo: String
    let clinicName: String
    let clinicAddress: String
    let patientName: String
    let patientAddress: String
    let diagnosis: String
    let labTests: [String]
    let additionalNotes: String

}

struct AppointmentDetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    
    
    
    let appointment: Appointment
     // to be changed after Fetch
    
    @State private var selectedImage: UIImage?
    @State private var diagnosticTests: String = ""
    @State private var medicines: [String] = []
    @State private var newMedicine: String = ""
    
    // Add new state variables for prescription
    @State private var diagnosis: String = ""
    @State private var selectedLabTests: Set<String> = []
    @State private var customLabTest: String = ""
    @State private var additionalNotes: String = ""
    
    @State private var showingLabTestPicker = false
    @State private var showingMedicinePicker = false
    @State private var searchMedicine = ""
    @State private var selectedMedicines: [Medicine] = []
    @State private var isSearching = false
    
    @State private var prescriptionPDF: Data?
    @State private var showingShareSheet = false
    @State private var showingPrescriptionPreview = false
    
    // Predefined lab tests
    let availableLabTests = [
        "Complete Blood Count",
        "Blood Sugar Test",
        "Lipid Profile",
        "Thyroid Function Test",
        "Liver Function Test",
        "Kidney Function Test",
        "X-Ray",
        "ECG"
    ]
    
    // Patient's Medical Information (Static) access threw id
    let bloodGroup = "O+"
    let allergies = "Peanuts, Pollen"
    let existingMedicalRecord = "Diabetes, Hypertension"
    let currentMedication = "Metformin"
    let pastSurgeries = "Appendectomy (2018)"
    let emergencyContact = "+91 9876543210"
    
    // Add this medicine model
    struct Medicine: Identifiable, Hashable {
        let id = UUID()
        let name: String
        var dosage: String
        var duration: String
        var timing: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                //                List {
                //                    // **Appointment Details Section**
                //                    Section(header: Text("Appointment Details").font(.headline)) {
                //                        InfoRowAppointment(label: "Patient Name", value: appointment.patientName)
                //                        InfoRowAppointment(label: "Appointment Type", value: appointment.visitType)
                //                        InfoRowAppointment(label: "Date & Time", value: appointment.dateTime)
                //                        InfoRowAppointment(label: "Status", value: appointment.status)
                //                    }
                
                List {
                    // **Appointment Details Section**
                    Section(header: Text("Appointment Details").font(.headline)) {
                        //                    InfoRowAppointment(label: "Patient Name", value: appointment.patientName)  to be fetched by patient ID
                        InfoRowAppointment(label: "Appointment Type", value: appointment.type.rawValue)
                        InfoRowAppointment(label: "Date & Time", value: formatDate(appointment.date))
                        
                        InfoRowAppointment(label: "Status", value: appointment.status.rawValue)
                    }
                    
                    
                    // **Patient's Medical Information**
                    Section(header: Text("Patient's Medical Information").font(.headline)) {
                        InfoRowAppointment(label: "Blood Group", value: bloodGroup)
                        InfoRowAppointment(label: "Allergies", value: allergies)
                        InfoRowAppointment(label: "Medical History", value: existingMedicalRecord)
                        InfoRowAppointment(label: "Current Medication", value: currentMedication)
                        InfoRowAppointment(label: "Past Surgeries", value: pastSurgeries)
                        InfoRowAppointment(label: "Emergency Contact", value: emergencyContact)
                    }
                    
                    // Prescription Section
                    Section(header: Text("Prescription").font(.headline)) {
                        DiagnosisSection(diagnosis: $diagnosis)
                        LabTestsSection(selectedLabTests: $selectedLabTests, showingLabTestPicker: $showingLabTestPicker)
                        NotesSection(notes: $additionalNotes)
                    }
                }
                
                // Add View Prescription Button at bottom
                Button(action: {
                    generateAndShowPrescription()
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View Prescription")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Appointment Details")
            .navigationBarItems(trailing: Button("Save") {
                savePrescription()
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingLabTestPicker) {
                LabTestPickerView(selectedTests: $selectedLabTests, availableTests: availableLabTests)
            }
            .sheet(isPresented: $showingPrescriptionPreview) {
                if let pdfData = prescriptionPDF {
                    PDFPreviewView(pdfData: pdfData)
                }
            }
        }
    }
    
    // Add function to handle saving prescription
    func savePrescription() {
        let prescriptionData = PrescriptionData(
            id: "123", // Generate unique ID
            date: Date().formatted(date: .long, time: .shortened),
            doctorName: "Dr. Onkar Bhave",
            doctorQualification: "M.B.B.S., M.D., M.S.",
            doctorRegNo: "270988",
            clinicName: "Care Clinic",
            clinicAddress: "Near Axis Bank, Kothrud, Pune - 411038",
            patientName: "name to be fetched by ID",
            patientAddress: "Pune", // Add to appointment model
            diagnosis: "diagnosis to be added",
            labTests: ["labTest1","Labtest2"],
            additionalNotes: "Notes to be added"
        )
        
        if let pdfData = PDFGenerator.generatePrescriptionPDF(data: prescriptionData) {
            self.prescriptionPDF = pdfData
            showingPrescriptionPreview = true
            
            // Save to your data model/database here
            // Example: appointment.prescriptionPDF = pdfData
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
    
    // Add this function to generate and show prescription
    private func generateAndShowPrescription() {
        let prescriptionData = PrescriptionData(
            id: "123",
            date: Date().formatted(date: .long, time: .shortened),
            doctorName: "Dr. Onkar Bhave",
            doctorQualification: "M.B.B.S., M.D., M.S.",
            doctorRegNo: "270988",
            clinicName: "Care Clinic",
            clinicAddress: "Near Axis Bank, Kothrud, Pune - 411038",
            patientName: "Name to be changed",
            patientAddress: "Pune",
            diagnosis: "diagnosis to be added",
            labTests: ["labTest1","Labtest2"],
            additionalNotes: "Notes to be added"
        )
        
        if let pdfData = PDFGenerator.generatePrescriptionPDF(data: prescriptionData) {
            self.prescriptionPDF = pdfData
            self.showingPrescriptionPreview = true
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
    
    
    // Add this new view for the Lab Test Picker
    struct LabTestPickerView: View {
        @Environment(\.presentationMode) var presentationMode
        @Binding var selectedTests: Set<String>
        let availableTests: [String]
        
        var body: some View {
            NavigationView {
                List {
                    ForEach(availableTests, id: \.self) { test in
                        HStack {
                            Text(test)
                            Spacer()
                            if selectedTests.contains(test) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTests.contains(test) {
                                selectedTests.remove(test)
                            } else {
                                selectedTests.insert(test)
                            }
                        }
                    }
                }
                .navigationTitle("Select Lab Tests")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // First, let's create separate view components for each section
    struct DiagnosisSection: View {
        @Binding var diagnosis: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Diagnosis")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                TextEditor(text: $diagnosis)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.vertical, 8)
        }
    }
    
    struct LabTestsSection: View {
        @Binding var selectedLabTests: Set<String>
        @Binding var showingLabTestPicker: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Lab Tests")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Button(action: {
                        showingLabTestPicker = true
                    }) {
                        Label("Add Tests", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                if selectedLabTests.isEmpty {
                    Text("No lab tests selected")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(Array(selectedLabTests), id: \.self) { test in
                        LabTestRow(test: test) {
                            selectedLabTests.remove(test)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    struct LabTestRow: View {
        let test: String
        let onDelete: () -> Void
        
        var body: some View {
            HStack {
                Text("• \(test)")
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    struct NotesSection: View {
        @Binding var notes: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Notes")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.vertical, 8)
        }
    }
    
    
    
    // Add PDF Generator class
    class PDFGenerator {
        static func generatePrescriptionPDF(data: PrescriptionData) -> Data? {
            let pdfMetaData = [
                kCGPDFContextCreator: "Hospital Management System",
                kCGPDFContextAuthor: data.doctorName
            ]
            let format = UIGraphicsPDFRendererFormat()
            format.documentInfo = pdfMetaData as [String: Any]
            
            let pageWidth = 8.5 * 72.0
            let pageHeight = 11 * 72.0
            let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
            
            let data = renderer.pdfData { context in
                context.beginPage()
                let context = context.cgContext
                
                // Draw content
                let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
                let regularFont = UIFont.systemFont(ofSize: 12)
                let smallFont = UIFont.systemFont(ofSize: 10)
                
                // Header
                drawText(data.clinicName, at: CGPoint(x: 40, y: 40), font: titleFont)
                drawText(data.clinicAddress, at: CGPoint(x: 40, y: 70), font: regularFont)
                drawText("Dr. \(data.doctorName)", at: CGPoint(x: 40, y: 90), font: regularFont)
                drawText(data.doctorQualification, at: CGPoint(x: 40, y: 110), font: smallFont)
                drawText("Reg No: \(data.doctorRegNo)", at: CGPoint(x: 40, y: 130), font: smallFont)
                
                
                // Divider
                drawLine(from: CGPoint(x: 40, y: 150), to: CGPoint(x: pageWidth - 40, y: 150))
                
                // Patient Details
                drawText("Patient ID: \(data.id)", at: CGPoint(x: 40, y: 170), font: regularFont)
                drawText("Name: \(data.patientName)", at: CGPoint(x: 40, y: 190), font: regularFont)
                drawText("Address: \(data.patientAddress)", at: CGPoint(x: 40, y: 210), font: regularFont)
                
                
                // Divider
                drawLine(from: CGPoint(x: 40, y: 250), to: CGPoint(x: pageWidth - 40, y: 250))
                
                // Diagnosis
                drawText("Diagnosis:", at: CGPoint(x: 40, y: 270), font: regularFont)
                drawText(data.diagnosis, at: CGPoint(x: 60, y: 290), font: regularFont)
                
                // Lab Tests
                var yPos = 320.0
                drawText("Lab Tests:", at: CGPoint(x: 40, y: yPos), font: regularFont)
                for test in data.labTests {
                    yPos += 20
                    drawText("• \(test)", at: CGPoint(x: 60, y: yPos), font: regularFont)
                }
                
                // Additional Notes
                yPos += 40
                drawText("Additional Notes:", at: CGPoint(x: 40, y: yPos), font: regularFont)
                drawText(data.additionalNotes, at: CGPoint(x: 60, y: yPos + 20), font: regularFont)
                
                // Follow Up
                
                drawLine(from: CGPoint(x: pageWidth - 200, y: pageHeight - 80),
                         to: CGPoint(x: pageWidth - 50, y: pageHeight - 80))
            }
            
            return data
        }
        
        private static func drawText(_ text: String, at point: CGPoint, font: UIFont) {
            let attributes = [
                NSAttributedString.Key.font: font
            ]
            (text as NSString).draw(at: point, withAttributes: attributes)
        }
        
        private static func drawLine(from startPoint: CGPoint, to endPoint: CGPoint) {
            let path = UIBezierPath()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            path.stroke()
        }
    }
    
    // Add ShareSheet for sharing PDF
    struct ShareSheet: UIViewControllerRepresentable {
        let items: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: items, applicationActivities: nil)
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    // Add this new view for PDF Preview
    struct PDFPreviewView: View {
        @Environment(\.presentationMode) var presentationMode
        let pdfData: Data
        
        var body: some View {
            NavigationView {
                PDFKitView(data: pdfData)
                    .navigationTitle("Prescription")
                    .navigationBarItems(
                        leading: Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        },
                        trailing: ShareLink(
                            item: pdfData,
                            preview: SharePreview(
                                "Prescription",
                                image: Image(systemName: "doc.text.fill")
                            )
                        )
                    )
            }
        }
    }
    
    // Add PDFKit View Representative
    struct PDFKitView: UIViewRepresentable {
        let data: Data
        
        func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = PDFDocument(data: data)
            pdfView.autoScales = true
            return pdfView
        }
        
        func updateUIView(_ uiView: PDFView, context: Context) {
            uiView.document = PDFDocument(data: data)
        }
    }
    
}





