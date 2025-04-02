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
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading prescription details...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        
                        // Diagnosis Section
                        prescriptionSection(
                            title: "Diagnosis",
                            content: prescription.diagnosis
                        )
                        
                        // Lab Tests Section
                        if let tests = prescription.labTests {
                            prescriptionSection(
                                title: "Lab Tests",
                                content: formatLabTests(tests)
                            )
                        }
                        
                        // Medicines Section
                        if let medicineName = prescription.medicineName,
                           !medicineName.isEmpty {
                            prescriptionSection(
                                title: "Medicines",
                                content: "\(medicineName)\n\(prescription.medicineDosage?.rawValue ?? "")\n\(prescription.medicineDuration?.rawValue ?? "")"
                            )
                        }
                        
                        // Additional Notes Section
                        if let notes = prescription.additionalNotes,
                           !notes.isEmpty {
                            prescriptionSection(
                                title: "Additional Notes",
                                content: notes
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Prescription Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    generateAndSharePDF()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
        .task {
            await loadDetails()
        }
    }
    
    private func loadDetails() async {
        do {
            // Fetch doctor details
            doctor = try await supabaseController.fetchDoctorById(doctorId: prescription.doctorId)
            
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
            }
        }
    }
    
    private func generateAndSharePDF() {
        guard let doctor = doctor,
              let hospital = hospital,
              let appointment = appointment else { return }
        
        if let generatedPDF = PDFGenerator.generatePrescriptionPDF(
            data: prescription,
            doctor: doctor,
            hospital: hospital
        ) {
            self.pdfData = generatedPDF
            self.showingShareSheet = true
        }
    }
    
    private func prescriptionSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.mint)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatLabTests(_ tests: [String]) -> String {
        if tests.isEmpty { return "No lab tests prescribed" }
        
        // If it's a single string (from database), split it
        if tests.count == 1 && tests[0].contains(",") {
            let splitTests = tests[0].split(separator: ",").map(String.init)
            return "• " + splitTests.joined(separator: "\n• ")
        }
        
        return "• " + tests.joined(separator: "\n• ")
    }
}

// ShareSheet for iOS sharing functionality
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
