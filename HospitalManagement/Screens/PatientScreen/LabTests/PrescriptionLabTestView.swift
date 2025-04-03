import SwiftUI

struct PrescriptionLabTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseController()
    @State private var prescriptions: [PrescriptionData] = []
    @State private var isLoading = true
    @State private var showBooking = false
    @State private var selectedPrescription: PrescriptionData?
    @State private var errorMessage: String?
    @State private var doctorNames: [UUID: String] = [:]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if prescriptions.isEmpty {
                ContentUnavailableView(
                    "No Prescriptions",
                    systemImage: "doc.text.fill",
                    description: Text("You don't have any prescriptions")
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(prescriptions, id: \.id) { prescription in
                        PrescriptionCard(
                            prescription: prescription,
                            doctorName: doctorNames[prescription.doctorId] ?? "Doctor"
                        )
                        .onTapGesture {
                            selectedPrescription = prescription
                            showBooking = true
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Select Prescription")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                await loadPrescriptions()
            }
        }
        .sheet(isPresented: $showBooking) {
            if let prescription = selectedPrescription {
                LabTestBookingView(prescription: prescription)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadPrescriptions() async {
        isLoading = true
        print("🔍 Starting prescription fetch...")
        
        do {
            guard let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
                  let patientId = UUID(uuidString: patientIdString) else {
                errorMessage = "Patient ID not found"
                isLoading = false
                return
            }
            
            print("✅ Found patient ID: \(patientIdString)")
            
            // First fetch prescriptions
            print("🔄 Fetching prescriptions from Supabase...")
            let fetchedPrescriptions: [PrescriptionData] = try await supabase.client
                .from("PrescriptionData")
                .select()
                .eq("patientId", value: patientId.uuidString)
                .execute()
                .value
            
            print("📊 Fetched prescriptions count: \(fetchedPrescriptions.count)")
            
            // Then fetch doctor names
            print("👨‍⚕️ Fetching doctor names...")
            var doctorNamesDict: [UUID: String] = [:]
            for prescription in fetchedPrescriptions {
                print("🔍 Fetching doctor info for ID: \(prescription.doctorId)")
                if let doctor = try? await supabase.fetchDoctorById(doctorId: prescription.doctorId) {
                    doctorNamesDict[prescription.doctorId] = doctor.full_name
                    print("✅ Found doctor: \(doctor.full_name)")
                }
            }
            
            await MainActor.run {
                print("🔄 Updating UI with fetched data...")
                self.prescriptions = fetchedPrescriptions
                self.doctorNames = doctorNamesDict
                self.isLoading = false
                print("✅ UI update complete. Prescriptions count: \(self.prescriptions.count)")
            }
            
        } catch {
            print("❌ Error fetching prescriptions: \(error)")
            print("🔍 Detailed error: \(String(describing: error))")
            await MainActor.run {
                errorMessage = error.localizedDescription
                prescriptions = []
                isLoading = false
            }
        }
    }
}

struct PrescriptionCard: View {
    let prescription: PrescriptionData
    let doctorName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Doctor Name
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.mint)
                Text(doctorName)
                    .font(.headline)
            }
            
            // Lab Tests
            if let tests = prescription.labTests, !tests.isEmpty {
                Text("Recommended Tests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                ForEach(tests, id: \.self) { test in
                    HStack {
                        Image(systemName: "flask.fill")
                            .foregroundColor(.mint)
                        Text(test)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        PrescriptionLabTestView()
    }
}


