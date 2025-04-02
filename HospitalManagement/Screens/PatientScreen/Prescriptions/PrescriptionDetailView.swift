import SwiftUI
import PDFKit

struct PrescriptionDetailView: View {
    let prescription: PrescriptionData
    let doctorName: String
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @StateObject private var supabaseController = SupabaseController()
    @State private var doctor: Doctor?
    @State private var hospital: Hospital?
    @State private var appointment: Appointment?
    @State private var patient: Patient?
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Doctor Info Card
                DetailCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dr. \(doctorName)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let appointmentDate = appointment?.date {
                            Text(formatDate(appointmentDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Diagnosis Card
                DetailCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diagnosis")
                            .font(.headline)
                            .foregroundColor(.teal)
                        
                        Text(prescription.diagnosis)
                            .font(.body)
                    }
                }
                
                // Lab Tests Card
                if let tests = prescription.labTests, !tests.isEmpty {
                    DetailCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lab Tests")
                                .font(.headline)
                                .foregroundColor(.teal)
                            
                            ForEach(cleanLabTests(tests), id: \.self) { test in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(test)
                                }
                                .font(.body)
                            }
                        }
                    }
                }
                
                // Medicines Card
                if let medicine = prescription.medicineName {
                    DetailCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medicines")
                                .font(.headline)
                                .foregroundColor(.teal)
                            
                            Text(medicine)
                                .font(.body)
                        }
                    }
                }
                
                // Additional Notes Card
                if let notes = prescription.additionalNotes {
                    DetailCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Notes")
                                .font(.headline)
                                .foregroundColor(.teal)
                            
                            Text(notes)
                                .font(.body)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Prescription Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await generateAndSharePDF()
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isLoading)
            }
        }
        .task {
            await loadDetails()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadDetails() async {
        isLoading = true
        do {
            // Fetch doctor details
            doctor = try await supabaseController.fetchDoctorById(doctorId: prescription.doctorId)
            
            // Fetch patient details
            patient = try await supabaseController.fetchPatientById(patientId: prescription.patientId)
            
            // Fetch appointment details
            let appointments: [Appointment] = try await supabaseController.client
                .from("Appointment")
                .select()
                .eq("prescriptionId", value: prescription.id.uuidString)
                .execute()
                .value
            
            // Fetch hospital details if doctor is found
            if let doctorData = doctor, let hospitalId = doctorData.hospital_id {
                let hospitals: [Hospital] = try await supabaseController.client
                    .from("Hospital")
                    .select()
                    .eq("id", value: hospitalId.uuidString)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.hospital = hospitals.first
                    self.appointment = appointments.first
                    self.isLoading = false
                }
            }
        } catch {
            print("Error loading details:", error)
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load prescription details"
                self.showingError = true
            }
        }
    }
    
    private func generateAndSharePDF() async {
        guard let doctor = doctor,
              let hospital = hospital,
              let patient = patient else {
            errorMessage = "Missing required information to generate PDF"
            showingError = true
            return
        }
        
        let pdfCreator = PDFCreator()
        if let generatedPDF = pdfCreator.createPrescriptionPDF(
            hospital: hospital,
            doctor: doctor,
            patient: patient,
            prescription: prescription,
            date: Date()
        ) {
            await MainActor.run {
                self.pdfData = generatedPDF
                self.showingShareSheet = true
            }
        } else {
            await MainActor.run {
                self.errorMessage = "Failed to generate PDF"
                self.showingError = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func cleanLabTests(_ tests: [String]) -> [String] {
        return tests.map { test in
            test.replacingOccurrences(of: "[\"", with: "")
                .replacingOccurrences(of: "\"]", with: "")
                .replacingOccurrences(of: "\"", with: "")
        }
    }
}

struct DetailCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class PDFCreator {
    private func calculateAge(from dateOfBirth: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return "\(ageComponents.year ?? 0)"
    }
    
    func createPrescriptionPDF(
        hospital: Hospital,
        doctor: Doctor,
        patient: Patient,
        prescription: PrescriptionData,
        date: Date
    ) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let headerFont = UIFont.systemFont(ofSize: 16, weight: .bold)
            let titleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            let regularFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            
            // Draw border
            context.cgContext.setStrokeColor(UIColor.gray.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.stroke(CGRect(x: 40, y: 40, width: pageRect.width - 80, height: pageRect.height - 80))
            
            var yPosition = 60
            
            // Hospital Header - Left side
            let hospitalInfo = NSAttributedString(
                string: "\(hospital.name)\n\(hospital.address)\n\(hospital.city), \(hospital.state) - \(hospital.pincode)\nPhone: \(hospital.mobile_number)\nEmail: \(hospital.email)",
                attributes: [.font: regularFont]
            )
            hospitalInfo.draw(at: CGPoint(x: 60, y: CGFloat(yPosition)))
            
            // Doctor Info - Right side
            let doctorInfo = NSAttributedString(
                string: "Dr. \(doctor.full_name)\n\(doctor.qualifications)\nReg. No: \(doctor.license_num ?? "")",
                attributes: [.font: regularFont]
            )
            doctorInfo.draw(at: CGPoint(x: pageRect.width - 250, y: CGFloat(yPosition)))
            
            // Horizontal line after header
            yPosition += 100
            drawLine(context: context.cgContext, startX: 60, endX: Int(pageRect.width - 60), y: yPosition)
            
            // Patient Info
            yPosition += 30
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy"
            
            // Calculate age from date of birth
            let age = calculateAge(from: patient.dateofbirth)
            
            let patientInfo = NSAttributedString(
                string: "Patient Name: \(patient.fullname)          Age: \(age)          Gender: \(patient.gender ?? "")",
                attributes: [.font: regularFont]
            )
            patientInfo.draw(at: CGPoint(x: 60, y: CGFloat(yPosition)))
            
            // Rx Symbol
            yPosition += 30
            let rx = NSAttributedString(
                string: "Rx.",
                attributes: [.font: titleFont]
            )
            rx.draw(at: CGPoint(x: 60, y: CGFloat(yPosition)))
            
            // Diagnosis
            yPosition += 30
            let diagnosisTitle = NSAttributedString(
                string: "Diagnosis:",
                attributes: [.font: titleFont]
            )
            diagnosisTitle.draw(at: CGPoint(x: 60, y: CGFloat(yPosition)))
            
            yPosition += 25
            let diagnosis = NSAttributedString(
                string: prescription.diagnosis,
                attributes: [.font: regularFont]
            )
            diagnosis.draw(at: CGPoint(x: 80, y: CGFloat(yPosition)))
            
            // Medicines
            yPosition += 40
            if let medicines = prescription.medicineName {
                let medicinesTitle = NSAttributedString(
                    string: "Medicines:",
                    attributes: [.font: titleFont]
                )
                medicinesTitle.draw(at: CGPoint(x: 60, y: CGFloat(yPosition)))
                
                // Split medicines by comma and display each on new line
                let medicinesList = medicines.components(separatedBy: ",")
                yPosition += 25
                
                for medicine in medicinesList {
                    let medicineText = NSAttributedString(
                        string: "• \(medicine.trimmingCharacters(in: .whitespaces))",
                        attributes: [.font: regularFont]
                    )
                    medicineText.draw(at: CGPoint(x: 80, y: CGFloat(yPosition)))
                    yPosition += 20
                }
            }
            
            // Lab Tests
            yPosition += 20
            if let tests = prescription.labTests, !tests.isEmpty {
                let testsTitle = NSAttributedString(
                    string: "Lab Tests:",
                    attributes: [.font: titleFont]
                )
                testsTitle.draw(at: CGPoint(x: 60, y: CGFloat(yPosition)))
                
                let cleanedTests = tests.map { test in
                    test.replacingOccurrences(of: "[\"", with: "")
                        .replacingOccurrences(of: "\"]", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                }
                
                yPosition += 25
                for test in cleanedTests {
                    let testText = NSAttributedString(
                        string: "• \(test.trimmingCharacters(in: .whitespaces))",
                        attributes: [.font: regularFont]
                    )
                    testText.draw(at: CGPoint(x: 80, y: CGFloat(yPosition)))
                    yPosition += 20
                }
            }
            
            // Doctor's Signature
            let signature = NSAttributedString(
                string: "Doctor's Signature\n\nDr. \(doctor.full_name)",
                attributes: [.font: regularFont]
            )
            signature.draw(at: CGPoint(x: pageRect.width - 200, y: pageRect.height - 100))
        }
        
        return data
    }
    
    private func drawLine(context: CGContext, startX: Int, endX: Int, y: Int) {
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: startX, y: y))
        context.addLine(to: CGPoint(x: endX, y: y))
        context.strokePath()
    }
} 
