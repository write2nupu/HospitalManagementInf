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
        
        Task {
            print("📱 Checking for patient ID in UserDefaults...")
            if let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId") {
                print("✅ Found patient ID: \(patientIdString)")
                
                if let patientId = UUID(uuidString: patientIdString) {
                    print("✅ Valid UUID format for patient ID")
                    do {
                        print("🔄 Fetching prescriptions from Supabase...")
                        let fetchedPrescriptions: [PrescriptionData] = try await supabase.client
                            .from("PrescriptionData")
                            .select()
                            .eq("patientId", value: patientId.uuidString)
                            .execute()
                            .value
                        
                        print("📊 Fetched prescriptions count: \(fetchedPrescriptions.count)")
                        print("📝 Prescription data: \(fetchedPrescriptions)")
                        
                        print("👨‍⚕️ Fetching doctor names...")
                        var doctorNamesDict: [UUID: String] = [:]
                        for prescription in fetchedPrescriptions {
                            print("🔍 Fetching doctor info for ID: \(prescription.doctorId)")
                            if let doctor = try? await supabase.fetchDoctorById(doctorId: prescription.doctorId) {
                                doctorNamesDict[prescription.doctorId] = doctor.full_name
                                print("✅ Found doctor: \(doctor.full_name)")
                            } else {
                                print("⚠️ Could not find doctor for ID: \(prescription.doctorId)")
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
                            self.errorMessage = error.localizedDescription
                            self.prescriptions = []
                            self.isLoading = false
                        }
                    }
                } else {
                    print("❌ Invalid UUID format for patient ID: \(patientIdString)")
                    await MainActor.run {
                        self.errorMessage = "Invalid patient ID format"
                        self.isLoading = false
                    }
                }
            } else {
                print("❌ No patient ID found in UserDefaults")
                await MainActor.run {
                    self.errorMessage = "Patient ID not found"
                    self.isLoading = false
                }
            }
        }
    }
}

struct PrescriptionCard: View {
    let prescription: PrescriptionData
    let doctorName: String
    
    private func cleanTestName(_ test: String) -> String {
        // Remove quotes, square brackets, and trim whitespace
        return test.trimmingCharacters(in: .init(charactersIn: "[]\"' "))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Doctor Info
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.mint)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dr. \(doctorName)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Lab Tests Section
            if let tests = prescription.labTests, !tests.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommended Tests")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(tests, id: \.self) { test in
                            HStack(spacing: 12) {
                                Image(systemName: "cross.case.fill")
                                    .foregroundColor(.mint)
                                    .font(.system(size: 14))
                                
                                Text(cleanTestName(test))
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
            
            // Diagnosis Section
            if !prescription.diagnosis.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diagnosis")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(prescription.diagnosis)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
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


