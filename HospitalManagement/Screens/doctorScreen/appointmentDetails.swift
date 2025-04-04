import SwiftUI
import PhotosUI
import PDFKit

// Add this PDFGenerator class before the AppointmentDetailView struct
class PDFGenerator {
   static func generatePrescriptionPDF(data: PrescriptionData, doctor: Doctor, hospital: Hospital) -> Data? {
       let pdfMetaData = [
           kCGPDFContextCreator: "Hospital Management System",
           kCGPDFContextAuthor: doctor.full_name
       ]
       let format = UIGraphicsPDFRendererFormat()
       format.documentInfo = pdfMetaData as [String: Any]
       
       let pageWidth = 8.5 * 72.0
       let pageHeight = 11 * 72.0
       let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
       
       let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
       
       let data = renderer.pdfData { context in
           context.beginPage()
           
           // Fonts
           let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
           let headerFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
           let regularFont = UIFont.systemFont(ofSize: 12)
           let smallFont = UIFont.systemFont(ofSize: 10)
           
           var yPos = 40.0
           
           // Hospital Header
           drawText(hospital.name, at: CGPoint(x: 40, y: yPos), font: titleFont)
           yPos += 25
           drawText(hospital.address, at: CGPoint(x: 40, y: yPos), font: smallFont)
           yPos += 15
           drawText("\(hospital.city), \(hospital.state) - \(hospital.pincode)", at: CGPoint(x: 40, y: yPos), font: smallFont)
           yPos += 15
           drawText("Phone: \(hospital.mobile_number) | Email: \(hospital.email)", at: CGPoint(x: 40, y: yPos), font: smallFont)
           
           // Divider line
           yPos += 20
           let path = UIBezierPath()
           path.move(to: CGPoint(x: 40, y: yPos))
           path.addLine(to: CGPoint(x: pageWidth - 40, y: yPos))
           path.lineWidth = 1
           UIColor.gray.setStroke()
           path.stroke()
           
           // Doctor Details
           yPos += 25
           drawText("Dr. \(doctor.full_name)", at: CGPoint(x: 40, y: yPos), font: headerFont)
           yPos += 20
           drawText("\(doctor.qualifications)", at: CGPoint(x: 40, y: yPos), font: regularFont)
           yPos += 15
           drawText("Reg. No: \(doctor.license_num)", at: CGPoint(x: 40, y: yPos), font: regularFont)
           
           // Patient Details
           yPos += 30
           drawText("Patient ID: \(data.patientId)", at: CGPoint(x: 40, y: yPos), font: regularFont)
           yPos += 20
           drawText("Date: \(formatDate(Date()))", at: CGPoint(x: 40, y: yPos), font: regularFont)
           
           // Diagnosis
           yPos += 30
           drawText("Diagnosis:", at: CGPoint(x: 40, y: yPos), font: headerFont)
           yPos += 20
           drawText(data.diagnosis, at: CGPoint(x: 60, y: yPos), font: regularFont)
           
           // Lab Tests
           if let tests = data.labTests, !tests.isEmpty {
               yPos += 30
               drawText("Lab Tests:", at: CGPoint(x: 40, y: yPos), font: headerFont)
               for test in tests {
                   yPos += 20
                   drawText("• \(test)", at: CGPoint(x: 60, y: yPos), font: regularFont)
               }
           }
           
           // Medicines - Only show if medicineName is not empty
           if let medicineName = data.medicineName, !medicineName.isEmpty {
               yPos += 30
               drawText("Medicines:", at: CGPoint(x: 40, y: yPos), font: headerFont)
               yPos += 20
               drawText("• \(medicineName)", at: CGPoint(x: 60, y: yPos), font: regularFont)
               if let dosage = data.medicineDosage, let duration = data.medicineDuration {
                   yPos += 15
                   drawText("  \(dosage.rawValue) for \(duration.rawValue)", at: CGPoint(x: 60, y: yPos), font: regularFont)
               }
           }
           
           // Additional Notes
           if let notes = data.additionalNotes, !notes.isEmpty {
               yPos += 30
               drawText("Additional Notes:", at: CGPoint(x: 40, y: yPos), font: headerFont)
               yPos += 20
               drawText(notes, at: CGPoint(x: 60, y: yPos), font: regularFont)
           }
           
           // Doctor's Signature
           yPos = pageHeight - 100
           drawText("Doctor's Signature", at: CGPoint(x: pageWidth - 200, y: yPos), font: regularFont)
           yPos += 30
           drawText("Dr. \(doctor.full_name)", at: CGPoint(x: pageWidth - 200, y: yPos), font: regularFont)
       }
       
       return data
   }
   
   private static func drawText(_ text: String, at point: CGPoint, font: UIFont) {
       let attributes = [
           NSAttributedString.Key.font: font
       ]
       (text as NSString).draw(at: point, withAttributes: attributes)
   }
   
   private static func formatDate(_ date: Date) -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "dd MMM yyyy"
       return formatter.string(from: date)
   }
}

// First, add this class at the top level of your file
class Debouncer {
   private let delay: TimeInterval
   private var workItem: DispatchWorkItem?
   
   init(delay: TimeInterval) {
       self.delay = delay
   }
   
   func debounce(action: @escaping () -> Void) {
       workItem?.cancel()
       let newWorkItem = DispatchWorkItem(block: action)
       workItem = newWorkItem
       DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
   }
}

// Add this struct at the top of the file
struct PrescriptionRequestData: Encodable {
   let id: String
   let patientId: String
   let doctorId: String
   let diagnosis: String
   let labTests: [String]
   let additionalNotes: String
   let medicineName: String
   let medicineDosage: String
   let medicineDuration: String
}

struct AppointmentDetailView: View {
   @Environment(\.presentationMode) var presentationMode
   @StateObject private var supabase = SupabaseController()
   
   let appointment: Appointment
   var onStatusUpdate: ((AppointmentStatus) -> Void)? // Add callback for status update
   
   @State private var selectedImage: UIImage?
   @State private var diagnosticTests: String = ""
   @State private var existingPrescription: PrescriptionData?
   @State private var isLoadingPrescription = true
   @State private var prescriptionError: Error?
   @State private var isEditable: Bool = false
   @State private var currentStatus: AppointmentStatus // Add state for current status
   
   // Add new state variables for prescription
   @State private var diagnosis: String = ""
   @State private var selectedLabTests: Set<String> = []
   @State private var customLabTest: String = ""
   @State private var additionalNotes: String = ""
   @State private var diagnosisError: String? = nil
   
   @State private var showingLabTestPicker = false
   @State private var prescriptionPDF: Data?
   @State private var showingShareSheet = false
   @State private var showingPrescriptionPreview = false
   @State private var showingDateError = false
   
   // Medicine-related state
   @State private var medicineName: String = ""
   @State private var selectedDosage: DosageOption = .oneDaily
   @State private var selectedDuration: DurationOption = .sevenDays
   
   // Predefined lab tests
   let availableLabTests = [
       "Complete Blood Count",
       "Blood Sugar Test",
       "Lipid Profile",
       "Thyroid Function Test",
       "Liver Function Test",
       "Kidney Function Test",
       "X-Ray",
       "ECG",
       "Urine Analysis",
       "HbA1c",
       "C-Reactive Protein",
       "Erythrocyte Sedimentation Rate (ESR)",
       "Iron Studies",
       "Electrolytes Test",
       "Coagulation Profile",
       "Vitamin D Test",
       "Vitamin B12 Test",
       "Calcium Test",
       "Prostate Specific Antigen (PSA)",
       "Pap Smear",
       "Mammogram",
       "Echocardiogram",
       "Pulmonary Function Test",
       "Stool Examination",
       "Amylase Test",
       "Lipase Test",
       "Blood Culture",
       "Urine Culture",
       "Fasting Blood Sugar",
       "Postprandial Blood Sugar"
   ];

   @State private var showingMedicineSelection = false
   @State private var prescribedMedicines: [PrescribedMedicine] = []
   
   // Computed property for form validation
   private var isFormValid: Bool {
       // Check if diagnosis is not empty and has at least 10 characters
       let isDiagnosisValid = !diagnosis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                             diagnosis.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
       
       // Update diagnosis error message
       if diagnosis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
           diagnosisError = "Diagnosis is required"
       } else if diagnosis.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
           diagnosisError = "Diagnosis must be at least 10 characters"
       } else {
           diagnosisError = nil
       }
       
       return isDiagnosisValid
   }

   init(appointment: Appointment, onStatusUpdate: ((AppointmentStatus) -> Void)? = nil) {
       self.appointment = appointment
       self.onStatusUpdate = onStatusUpdate
       _currentStatus = State(initialValue: appointment.status)
   }

   var body: some View {
       NavigationView {
           VStack {
               if isLoadingPrescription {
                   ProgressView("Loading prescription...")
               } else {
                   List {
                       // Appointment Details Section
                       Section(header: Text("Appointment Details").font(.headline)) {
                           InfoRowAppointment(label: "Appointment Type", value: appointment.type.rawValue)
                           InfoRowAppointment(label: "Date & Time", value: formatDate(appointment.date))
                           
                           // Add status picker if appointment is not cancelled
                           if appointment.status != .cancelled {
                               Picker("Status", selection: $currentStatus) {
                                   Text("Scheduled").tag(AppointmentStatus.scheduled)
                                   Text("Completed").tag(AppointmentStatus.completed)
                               }
                               .pickerStyle(SegmentedPickerStyle())
                               .onChange(of: currentStatus) { oldValue, newStatus in
                                   updateAppointmentStatus(to: newStatus)
                               }
                           } else {
                               InfoRowAppointment(label: "Status", value: appointment.status.rawValue)
                           }
                       }
                       
                       // Prescription Section
                       Section(header: Text("Prescription").font(.headline)) {
                           if let prescription = existingPrescription {
                               // Show existing prescription data in read-only mode
                               Text("Diagnosis: \(prescription.diagnosis)")
                               if let tests = prescription.labTests {
                                   Text("Lab Tests:")
                                   ForEach(tests, id: \.self) { test in
                                       Text("• \(test)")
                                   }
                               }
                               
                               // Medicine Section
                               if let medicineName = prescription.medicineName,
                                  let dosage = prescription.medicineDosage,
                                  let duration = prescription.medicineDuration {
                                   VStack(alignment: .leading, spacing: 4) {
                                       Text("Medicine: \(medicineName)")
                                           .font(.headline)
                                       Text("\(dosage.rawValue) - \(duration.rawValue)")
                                           .font(.subheadline)
                                           .foregroundColor(.gray)
                                   }
                                   .padding(.vertical, 4)
                               }
                               
                               if let notes = prescription.additionalNotes {
                                   Text("Additional Notes: \(notes)")
                               }
                           } else {
                               // Check if current date is on or after appointment date
                               let canAddPrescription = Calendar.current.isDateInToday(appointment.date) || Date() > appointment.date
                               
                               if !canAddPrescription {
                                   VStack(alignment: .center, spacing: 8) {
                                       Image(systemName: "calendar.badge.exclamationmark")
                                           .font(.system(size: 40))
                                           .foregroundColor(.orange)
                                       Text("Cannot add prescription yet")
                                           .font(.headline)
                                       Text("Prescriptions can only be added on or after the appointment date")
                                           .font(.subheadline)
                                           .foregroundColor(.gray)
                                           .multilineTextAlignment(.center)
                                   }
                                   .frame(maxWidth: .infinity)
                                   .padding()
                               } else {
                                   // Show prescription input fields only if no existing prescription
                                   VStack(alignment: .leading, spacing: 8) {
                                       Text("Diagnosis")
                                           .font(.subheadline)
                                           .foregroundColor(.gray)
                                       TextEditor(text: $diagnosis)
                                           .frame(height: 100)
                                           .padding(8)
                                           .background(Color(.systemGray6))
                                           .cornerRadius(8)
                                           .onChange(of: diagnosis) { oldValue, _ in
                                               // This will trigger validation and update error message
                                               _ = isFormValid
                                           }
                                       
                                       if let error = diagnosisError {
                                           Text(error)
                                               .font(.caption)
                                               .foregroundColor(.red)
                                       }
                                   }
                                   .disabled(!isEditable)
                                   
                                   LabTestsSection(selectedLabTests: $selectedLabTests, showingLabTestPicker: $showingLabTestPicker)
                                       .disabled(!isEditable)
                                   NotesSection(notes: $additionalNotes)
                                       .disabled(!isEditable)
                                   
                                   // Medicine Section
                                   Section(header: Text("MEDICINES").font(.headline)) {
                                       HStack {
                                           Text("Selected Medicines")
                                               .font(.subheadline)
                                               .foregroundColor(.gray)
                                           Spacer()
                                           if isEditable {
                                               Button(action: {
                                                   showingMedicineSelection = true
                                               }) {
                                                   Label("Add Medicine", systemImage: "plus.circle.fill")
                                                       .foregroundColor(AppConfig.buttonColor)
                                               }
                                           }
                                       }
                                       
                                       if prescribedMedicines.isEmpty {
                                           Text("No medicines selected")
                                               .foregroundColor(.gray)
                                               .italic()
                                       } else {
                                           ForEach(prescribedMedicines) { medicine in
                                               VStack(alignment: .leading) {
                                                   Text(medicine.medicine.name)
                                                       .font(.headline)
                                                   Text("\(medicine.dosage) for \(medicine.duration)")
                                                       .font(.subheadline)
                                                       .foregroundColor(.gray)
                                               }
                                               .padding(.vertical, 4)
                                           }
                                       }
                                   }
                               }
                           }
                       }
                   }
                   
                   // View Prescription Button
                   Button(action: {
                       generateAndShowPrescription()
                   }) {
                       HStack {
                           Image(systemName: "doc.text.fill")
                           Text("View Prescription")
                       }
                       .foregroundColor(.black)
                       .frame(maxWidth: .infinity)
                       .padding()
                       .background(AppConfig.buttonColor)
                       .cornerRadius(10)
                   }
                   .padding()
                   .disabled(!isFormValid && existingPrescription == nil) // Disable if form is not valid and there's no existing prescription
               }
           }
           .navigationTitle("Appointment Details")
           .navigationBarTitleDisplayMode(.inline)
           .navigationBarItems(trailing: Group {
               if isEditable && existingPrescription == nil {
                   Button("Save") {
                       // Check if current date is on or after appointment date
                       let canAddPrescription = Calendar.current.isDateInToday(appointment.date) || Date() > appointment.date
                       
                       if canAddPrescription {
                           savePrescription()
                           presentationMode.wrappedValue.dismiss()
                       } else {
                           showingDateError = true
                       }
                   }
                   .disabled(!isFormValid) // Disable save button if form is not valid
               }
           })
           .alert("Cannot Add Prescription", isPresented: $showingDateError) {
               Button("OK", role: .cancel) { }
           } message: {
               Text("Prescriptions can only be added on or after the appointment date.")
           }
           .task {
               await loadPrescription()
           }
           .onAppear {
               // Set isEditable based on whether there's an existing prescription
               isEditable = appointment.prescriptionId == nil
           }
           .sheet(isPresented: $showingLabTestPicker) {
               LabTestPickerView(selectedTests: $selectedLabTests, availableTests: availableLabTests)
           }
           .sheet(isPresented: $showingPrescriptionPreview) {
               if let pdfData = prescriptionPDF {
                   PDFPreviewView(pdfData: pdfData)
               }
           }
           .sheet(isPresented: $showingMedicineSelection) {
               MedicineSelectionView(prescribedMedicines: $prescribedMedicines)
           }
       }
   }
   
   private func loadPrescription() async {
       isLoadingPrescription = true
       do {
           if let prescriptionId = appointment.prescriptionId {
               print("Loading prescription for ID:", prescriptionId.uuidString)
               
               // First, get the raw data to handle the labTests field manually
               let result = try await supabase.client
                   .from("PrescriptionData")
                   .select("*")  // Explicitly select all columns
                   .eq("id", value: prescriptionId.uuidString)
                   .execute()
               
               // Debug print the raw response
               print("Raw Supabase response:", String(describing: result))
               
               // Get the raw data
               let rawData = result.data
               print("Raw data received:", rawData)
               
               // Try to convert Data to JSON
               if let jsonString = String(data: rawData, encoding: .utf8) {
                   print("JSON String:", jsonString)
                   
                   // Parse the JSON string
                   if let jsonData = jsonString.data(using: .utf8),
                      let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                       print("Successfully parsed JSON object:", jsonObject)
                       
                       // Custom decoder to handle the labTests field
                       let decoder = JSONDecoder()
                       decoder.dateDecodingStrategy = .iso8601
                       
                       struct RawPrescription: Codable {
                           let id: String
                           let patientId: String
                           let doctorId: String
                           let diagnosis: String
                           let labTests: String
                           let additionalNotes: String?
                           let medicineName: String?
                           let medicineDosage: String?
                           let medicineDuration: String?
                       }
                       
                       // Decode the raw data
                       let rawPrescriptions = try decoder.decode([RawPrescription].self, from: jsonData)
                       print("Successfully decoded prescriptions:", rawPrescriptions)
                       
                       if let rawPrescription = rawPrescriptions.first {
                           print("Processing raw prescription:", rawPrescription)
                           
                           // Convert the raw prescription to our PrescriptionData model
                           let prescription = PrescriptionData(
                               id: UUID(uuidString: rawPrescription.id) ?? UUID(),
                               patientId: UUID(uuidString: rawPrescription.patientId) ?? UUID(),
                               doctorId: UUID(uuidString: rawPrescription.doctorId) ?? UUID(),
                               diagnosis: rawPrescription.diagnosis,
                               labTests: try? JSONDecoder().decode([String].self, from: Data(rawPrescription.labTests.utf8)),
                               additionalNotes: rawPrescription.additionalNotes,
                               medicineName: rawPrescription.medicineName,
                               medicineDosage: DosageOption(rawValue: rawPrescription.medicineDosage ?? "") ?? .oneDaily,
                               medicineDuration: DurationOption(rawValue: rawPrescription.medicineDuration ?? "") ?? .sevenDays
                           )
                           
                           print("Successfully created PrescriptionData:", prescription)
                           
                           // Update the UI with the prescription data
                           existingPrescription = prescription
                           diagnosis = prescription.diagnosis
                           if let tests = prescription.labTests {
                               selectedLabTests = Set(tests)
                           }
                           additionalNotes = prescription.additionalNotes ?? ""
                           medicineName = prescription.medicineName ?? ""
                           
                           // If there's an existing prescription, disable editing
                           isEditable = false
                           
                           // Generate PDF for existing prescription
                           let doctorResult = try await supabase.client
                               .from("Doctor")
                               .select()
                               .eq("id", value: appointment.doctorId.uuidString)
                               .execute()
                           
                           if let doctorData = String(data: doctorResult.data, encoding: .utf8),
                              let doctorJsonData = doctorData.data(using: .utf8),
                              let doctorArray = try? JSONDecoder().decode([Doctor].self, from: doctorJsonData),
                              let doctor = doctorArray.first {
                                
                                let hospitalResult = try await supabase.client
                                    .from("Hospital")
                                    .select()
                                    .eq("id", value: doctor.hospital_id?.uuidString ?? "")
                                    .execute()
                                
                                if let hospitalData = String(data: hospitalResult.data, encoding: .utf8),
                                   let hospitalJsonData = hospitalData.data(using: .utf8),
                                   let hospitalArray = try? JSONDecoder().decode([Hospital].self, from: hospitalJsonData),
                                   let hospital = hospitalArray.first {
                                    
                                    // Generate PDF with hospital and doctor details for existing prescription
                                    if let pdfData = PDFGenerator.generatePrescriptionPDF(data: prescription, doctor: doctor, hospital: hospital) {
                                        self.prescriptionPDF = pdfData
                                    }
                                } else {
                                    print("Failed to decode hospital data")
                                }
                            } else {
                                print("Failed to decode doctor data")
                            }
                       } else {
                           print("No prescription found in the decoded data")
                       }
                   } else {
                       print("Failed to parse JSON")
                   }
               } else {
                   print("Failed to convert Data to String")
               }
           } else {
               // No existing prescription, enable editing
               isEditable = true
               existingPrescription = nil
           }
       } catch {
           print("Error loading prescription:", error)
           print("Detailed error:", String(describing: error))
           if let decodingError = error as? DecodingError {
               print("Decoding error details:", decodingError)
           }
       }
       isLoadingPrescription = false
   }
   
   func savePrescription() {
       // Double check if prescription already exists
       guard existingPrescription == nil && appointment.prescriptionId == nil else {
           print("Prescription already exists - cannot create new prescription")
           // If there's an existing prescription, show it instead
           if let existingPrescription = existingPrescription {
               Task {
                   do {
                       let doctorResult = try await supabase.client
                           .from("Doctor")
                           .select()
                           .eq("id", value: appointment.doctorId.uuidString)
                           .execute()
                       
                       guard let doctorData = doctorResult.data as? [[String: Any]],
                             let doctorJson = doctorData.first else {
                           print("Doctor not found")
                           return
                       }
                       
                       let doctorJsonData = try JSONSerialization.data(withJSONObject: doctorJson)
                       let doctor = try JSONDecoder().decode(Doctor.self, from: doctorJsonData)
                       
                       let hospitalResult = try await supabase.client
                           .from("Hospital")
                           .select()
                           .eq("id", value: doctor.hospital_id?.uuidString ?? "")
                           .execute()
                       
                       guard let hospitalData = hospitalResult.data as? [[String: Any]],
                             let hospitalJson = hospitalData.first else {
                           print("Hospital not found")
                           return
                       }
                       
                       let hospitalJsonData = try JSONSerialization.data(withJSONObject: hospitalJson)
                       let hospital = try JSONDecoder().decode(Hospital.self, from: hospitalJsonData)
                       
                       if let pdfData = PDFGenerator.generatePrescriptionPDF(data: existingPrescription, doctor: doctor, hospital: hospital) {
                           self.prescriptionPDF = pdfData
                           showingPrescriptionPreview = true
                       }
                   } catch {
                       print("Error generating PDF for existing prescription:", error)
                   }
               }
           }
           return
       }
       
       print("Starting to save prescription...")
       
       // Create medicine details string
       let medicineDetails = prescribedMedicines.map { medicine in
           "\(medicine.medicine.name) (\(medicine.dosage) for \(medicine.duration))"
       }.joined(separator: ", ")
       
       // Convert dosage and duration to proper enums
       let dosageOption = DosageOption(rawValue: prescribedMedicines.first?.dosage ?? "Once Daily") ?? .oneDaily
       let durationOption = DurationOption(rawValue: prescribedMedicines.first?.duration ?? "7 Days") ?? .sevenDays
       
       // Create new prescription with a new UUID
       let prescriptionId = UUID()
       let prescriptionData = PrescriptionData(
           id: prescriptionId,
           patientId: appointment.patientId,
           doctorId: appointment.doctorId,
           diagnosis: diagnosis,
           labTests: Array(selectedLabTests),
           additionalNotes: additionalNotes,
           medicineName: medicineDetails,
           medicineDosage: dosageOption,
           medicineDuration: durationOption
       )
       
       Task {
           do {
               // First fetch doctor and hospital details
               let doctors: [Doctor] = try await supabase.client
                   .from("Doctor")
                   .select()
                   .eq("id", value: appointment.doctorId.uuidString)
                   .execute()
                   .value
               
               guard let doctor = doctors.first else {
                   print("Doctor not found")
                   return
               }
               
               let hospitals: [Hospital] = try await supabase.client
                   .from("Hospital")
                   .select()
                   .eq("id", value: doctor.hospital_id?.uuidString ?? "")
                   .execute()
                   .value
               
               guard let hospital = hospitals.first else {
                   print("Hospital not found")
                   return
               }
               
               // Insert new prescription
               try await supabase.client
                   .from("PrescriptionData")
                   .insert(prescriptionData)
                   .execute()
               
               print("Successfully inserted new prescription")
               
               // Update the appointment with the prescription ID and status
               try await supabase.client
                   .from("Appointment")
                   .update([
                       "prescriptionId": prescriptionId.uuidString,
                       "status": AppointmentStatus.completed.rawValue
                   ])
                   .eq("id", value: appointment.id.uuidString)
                   .execute()
               
               print("Successfully updated appointment with prescription ID and status")
               
               // Generate PDF with hospital and doctor details
               if let pdfData = PDFGenerator.generatePrescriptionPDF(data: prescriptionData, doctor: doctor, hospital: hospital) {
                   self.prescriptionPDF = pdfData
                   showingPrescriptionPreview = true
                   print("PDF generated successfully")
               }
               
               // Update the existingPrescription to prevent further saves
               existingPrescription = prescriptionData
               isEditable = false
               
           } catch {
               print("Error saving prescription:", error)
           }
       }
   }
   
   private func generateAndShowPrescription() {
       Task {
           do {
               // First fetch doctor and hospital details
               let doctors: [Doctor] = try await supabase.client
                   .from("Doctor")
                   .select()
                   .eq("id", value: appointment.doctorId.uuidString)
                   .execute()
                   .value
               
               guard let doctor = doctors.first else {
                   print("Doctor not found")
                   return
               }
               
               let hospitals: [Hospital] = try await supabase.client
                   .from("Hospital")
                   .select()
                   .eq("id", value: doctor.hospital_id?.uuidString ?? "")
                   .execute()
                   .value
               
               guard let hospital = hospitals.first else {
                   print("Hospital not found")
                   return
               }
               
               let prescriptionData = existingPrescription ?? PrescriptionData(
                   id: UUID(),
                   patientId: appointment.patientId,
                   doctorId: appointment.doctorId,
                   diagnosis: diagnosis,
                   labTests: Array(selectedLabTests),
                   additionalNotes: additionalNotes,
                   medicineName: medicineName,
                   medicineDosage: selectedDosage,
                   medicineDuration: selectedDuration
               )
               
               if let pdfData = PDFGenerator.generatePrescriptionPDF(data: prescriptionData, doctor: doctor, hospital: hospital) {
                   self.prescriptionPDF = pdfData
                   self.showingPrescriptionPreview = true
               }
           } catch {
               print("Error generating prescription:", error)
           }
       }
   }
   
   func formatDate(_ date: Date) -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "MMM d, yyyy - h:mm a"
       return formatter.string(from: date)
   }
   
   // Helper Views
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
                           .foregroundColor(AppConfig.buttonColor)
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
   
   // Update the MedicineSelectionView
   struct MedicineSelectionView: View {
       @Environment(\.dismiss) private var dismiss
       @Binding var prescribedMedicines: [PrescribedMedicine]
       
       @State private var searchText = ""
       @State private var searchResults: [MedicineResponse] = []
       @State private var isSearching = false
       @State private var selectedMedicine: MedicineResponse?
       @State private var showingDosageSheet = false
       
       // Add debouncer
       private let searchDebouncer = Debouncer(delay: 0.4) // 400ms delay
       
       var body: some View {
           NavigationView {
               VStack(spacing: 0) {
                   // Search Bar - Fixed at top
                   HStack {
                       HStack(spacing: 8) {
                           Image(systemName: "magnifyingglass")
                               .foregroundColor(.gray)
                           
                           TextField("Search medicines...", text: $searchText)
                               .textFieldStyle(PlainTextFieldStyle())
                               .onChange(of: searchText) { oldValue, newValue in
                                   if !newValue.isEmpty && newValue.count >= 2 {
                                       // Use debouncer for search
                                       isSearching = true // Show loading immediately
                                       searchDebouncer.debounce {
                                           searchMedicines(query: newValue)
                                       }
                                   } else {
                                       searchResults = []
                                       isSearching = false
                                   }
                               }
                           
                           if !searchText.isEmpty {
                               Button(action: {
                                   withAnimation {
                                       searchText = ""
                                       searchResults = []
                                       isSearching = false
                                   }
                               }) {
                                   Image(systemName: "xmark.circle.fill")
                                       .foregroundColor(.gray)
                                       .padding(4)
                               }
                           }
                       }
                       .padding(10)
                       .background(Color(.systemGray6))
                       .cornerRadius(10)
                   }
                   .padding(.horizontal)
                   .padding(.top, 8)
                   .padding(.bottom, 4)
                   
                   // Content Area
                   if isSearching {
                       Spacer()
                       ProgressView("Searching...")
                       Spacer()
                   } else if searchResults.isEmpty && !searchText.isEmpty {
                       Spacer()
                       NoResultsView()
                       Spacer()
                   } else {
                       ScrollView {
                           LazyVStack(spacing: 12) {
                               ForEach(searchResults) { medicine in
                                   MedicineCard(medicine: medicine) {
                                       selectedMedicine = medicine
                                       showingDosageSheet = true
                                   }
                                   .padding(.horizontal)
                               }
                           }
                           .padding(.vertical)
                       }
                   }
               }
               .navigationTitle("Select Medicine")
               .navigationBarItems(
                   leading: Button("Cancel") { dismiss() }
               )
               .sheet(isPresented: $showingDosageSheet) {
                   if let medicine = selectedMedicine {
                       DosageSelectionView(medicine: medicine) { dosage, duration in
                           addMedicine(medicine, dosage: dosage, duration: duration)
                           dismiss()
                       }
                   }
               }
           }
       }
       
       private func searchMedicines(query: String) {
           guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
               isSearching = false
               return
           }
           
           let urlString = "https://hms-server-4kjy.onrender.com/search?name=\(encodedQuery)"
           guard let url = URL(string: urlString) else {
               isSearching = false
               return
           }
           
           print("Searching for: \(query)")
           print("URL: \(urlString)")
           
           URLSession.shared.dataTask(with: url) { data, response, error in
               DispatchQueue.main.async {
                   isSearching = false
                   
                   if let error = error {
                       print("Network error:", error.localizedDescription)
                       return
                   }
                   
                   guard let data = data else {
                       print("No data received")
                       return
                   }
                   
                   do {
                       let decoder = JSONDecoder()
                       let results = try decoder.decode([MedicineResponse].self, from: data)
                       print("Decoded \(results.count) medicines")
                       searchResults = results
                   } catch {
                       print("Decoding error:", error)
                       print("Response data:", String(data: data, encoding: .utf8) ?? "Unable to convert data to string")
                       searchResults = []
                   }
               }
           }.resume()
       }
       
       private func addMedicine(_ medicine: MedicineResponse, dosage: String, duration: String) {
           print("Adding new medicine:", medicine.name)
           print("Dosage:", dosage)
           print("Duration:", duration)
           
           let prescribed = PrescribedMedicine(
               medicine: medicine,
               dosage: dosage,
               duration: duration,
               timing: ""
           )
           prescribedMedicines.append(prescribed)
           print("Current prescribed medicines count:", prescribedMedicines.count)
       }
   }
   
   // Add these new view components
   struct NoResultsView: View {
       var body: some View {
           VStack(spacing: 16) {
               Circle()
                   .fill(Color.gray.opacity(0.1))
                   .frame(width: 70, height: 70)
                   .overlay(
                       Image(systemName: "magnifyingglass")
                           .font(.system(size: 30))
                           .foregroundColor(.gray)
                   )
               
               Text("No medicines found")
                   .font(.system(size: 17, weight: .semibold))
                   .foregroundColor(.primary)
               
               Text("Try searching with a different name")
                   .font(.system(size: 15))
                   .foregroundColor(.gray)
                   .multilineTextAlignment(.center)
           }
           .padding(30)
           .frame(maxWidth: .infinity)
       }
   }
   
   struct MedicineCard: View {
       let medicine: MedicineResponse
       let onSelect: () -> Void
       
       var body: some View {
           Button(action: onSelect) {
               HStack(spacing: 16) {
                   // Medicine Icon/Image
                   Circle()
                       .fill(Color.blue.opacity(0.1))
                       .frame(width: 50, height: 50)
                       .overlay(
                           Image(systemName: "pills.circle.fill")
                               .font(.system(size: 24))
                               .foregroundColor(.blue)
                       )
                   
                   // Medicine Details
                   VStack(alignment: .leading, spacing: 4) {
                       Text(medicine.name)
                           .font(.system(size: 17, weight: .semibold))
                           .foregroundColor(.primary)
                       
                       Text("Tap to select")
                           .font(.system(size: 14))
                           .foregroundColor(.gray)
                   }
                   
                   Spacer()
                   
                   // Chevron
                   Image(systemName: "chevron.right")
                       .foregroundColor(Color(.systemGray4))
                       .font(.system(size: 14, weight: .semibold))
               }
               .padding(.vertical, 12)
               .padding(.horizontal, 16)
               .background(Color(.systemBackground))
               .cornerRadius(12)
               .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
           }
           .buttonStyle(PlainButtonStyle())
           .padding(.horizontal)
           .padding(.vertical, 4)
       }
   }
   
   // Add this new view for dosage selection
   struct DosageSelectionView: View {
       let medicine: MedicineResponse
       let onComplete: (String, String) -> Void
       @Environment(\.dismiss) private var dismiss
       
       @State private var selectedDosage = "Once Daily"
       @State private var selectedDuration = "7 Days"
       
       let dosageOptions = ["Once Daily", "Twice Daily", "Thrice Daily", "Four times a day"]
       let durationOptions = ["3 Days", "5 Days", "7 Days", "10 Days", "15 Days", "30 Days"]
       
       var body: some View {
           NavigationView {
               Form {
                   Section(header: Text("Medicine")) {
                       Text(medicine.name)
                           .font(.headline)
                   }
                   
                   Section(header: Text("Dosage")) {
                       Picker("Dosage", selection: $selectedDosage) {
                           ForEach(dosageOptions, id: \.self) { option in
                               Text(option).tag(option)
                           }
                       }
                   }
                   
                   Section(header: Text("Duration")) {
                       Picker("Duration", selection: $selectedDuration) {
                           ForEach(durationOptions, id: \.self) { option in
                               Text(option).tag(option)
                           }
                       }
                   }
               }
               .navigationTitle("Prescription Details")
               .navigationBarItems(
                   leading: Button("Cancel") { dismiss() },
                   trailing: Button("Done") {
                       onComplete(selectedDosage, selectedDuration)
                       dismiss()
                   }
               )
           }
       }
   }
   
   private func updateAppointmentStatus(to newStatus: AppointmentStatus) {
       Task {
           do {
               try await supabase.updateAppointmentStatus(appointmentId: appointment.id, status: newStatus)
               await MainActor.run {
                   onStatusUpdate?(newStatus) // Notify parent view of the status change
               }
           } catch {
               print("Error updating appointment status: \(error)")
           }
       }
   }
}
