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
            let titleFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
            let regularFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let smallFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            
            // Hospital Header
            let hospitalName = NSAttributedString(
                string: hospital.name,
                attributes: [.font: headerFont]
            )
            hospitalName.draw(at: CGPoint(x: 50, y: 50))
            
            let hospitalAddress = NSAttributedString(
                string: "\(hospital.address)\n\(hospital.city), \(hospital.state) - \(hospital.pincode)",
                attributes: [.font: smallFont]
            )
            hospitalAddress.draw(at: CGPoint(x: 50, y: 70))
            
            let contactInfo = NSAttributedString(
                string: "Phone: \(hospital.mobile_number) | Email: \(hospital.email)",
                attributes: [.font: smallFont]
            )
            contactInfo.draw(at: CGPoint(x: 50, y: 100))
            
            // Separator Line
            context.cgContext.setStrokeColor(UIColor.gray.cgColor)
            context.cgContext.setLineWidth(0.5)
            context.cgContext.move(to: CGPoint(x: 50, y: 120))
            context.cgContext.addLine(to: CGPoint(x: 545, y: 120))
            context.cgContext.strokePath()
            
            // Doctor Info
            let doctorInfo = NSAttributedString(
                string: "Dr. \(doctor.full_name)\n\(doctor.qualifications ?? "")\nReg. No: \(doctor.license_num ?? "")",
                attributes: [.font: titleFont]
            )
            doctorInfo.draw(at: CGPoint(x: 50, y: 140))
            
            // Patient Info and Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy"
            let patientInfo = NSAttributedString(
                string: "Patient Name: \(patient.fullname)\nDate: \(dateFormatter.string(from: date))",
                attributes: [.font: regularFont]
            )
            patientInfo.draw(at: CGPoint(x: 50, y: 190))
            
            // Diagnosis
            let diagnosisTitle = NSAttributedString(
                string: "Diagnosis:",
                attributes: [.font: titleFont]
            )
            diagnosisTitle.draw(at: CGPoint(x: 50, y: 240))
            
            let diagnosis = NSAttributedString(
                string: prescription.diagnosis,
                attributes: [.font: regularFont]
            )
            diagnosis.draw(at: CGPoint(x: 70, y: 260))
            
            // Medicines
            var yPosition = 300
            if let medicines = prescription.medicineName {
                let medicinesTitle = NSAttributedString(
                    string: "Medicines:",
                    attributes: [.font: titleFont]
                )
                medicinesTitle.draw(at: CGPoint(x: 50, y: CGFloat(yPosition)))
                
                let medicinesList = NSAttributedString(
                    string: medicines,
                    attributes: [.font: regularFont]
                )
                medicinesList.draw(at: CGPoint(x: 70, y: CGFloat(yPosition + 20)))
                yPosition += 60
            }
            
            // Lab Tests
            if let tests = prescription.labTests, !tests.isEmpty {
                let testsTitle = NSAttributedString(
                    string: "Lab Tests:",
                    attributes: [.font: titleFont]
                )
                testsTitle.draw(at: CGPoint(x: 50, y: CGFloat(yPosition)))
                
                let cleanedTests = tests.map { test in
                    test.replacingOccurrences(of: "[\"", with: "")
                        .replacingOccurrences(of: "\"]", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                }
                
                let testsList = NSAttributedString(
                    string: cleanedTests.map { "• \($0)" }.joined(separator: "\n"),
                    attributes: [.font: regularFont]
                )
                testsList.draw(at: CGPoint(x: 70, y: CGFloat(yPosition + 20)))
                yPosition += 60 + (20 * tests.count)
            }
            
            // Additional Notes
            if let notes = prescription.additionalNotes {
                let notesTitle = NSAttributedString(
                    string: "Additional Notes:",
                    attributes: [.font: titleFont]
                )
                notesTitle.draw(at: CGPoint(x: 50, y: CGFloat(yPosition)))
                
                let notesList = NSAttributedString(
                    string: notes,
                    attributes: [.font: regularFont]
                )
                notesList.draw(at: CGPoint(x: 70, y: CGFloat(yPosition + 20)))
            }
            
            // Doctor's Signature
            let signature = NSAttributedString(
                string: "\n\nDoctor's Signature\n\nDr. \(doctor.full_name)",
                attributes: [.font: regularFont]
            )
            signature.draw(at: CGPoint(x: 350, y: CGFloat(yPosition + 100)))
        }
        
        return data
    }
} 
