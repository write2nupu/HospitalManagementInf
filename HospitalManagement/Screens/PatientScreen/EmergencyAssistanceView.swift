import SwiftUI

struct EmergencyAssistanceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseController()
    
    @State private var patient: Patient?
    @State private var hospital: Hospital?
    @State private var emergencyDescription = ""
    @State private var isBookingEmergency = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emergency Assistance")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Request immediate medical attention")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Patient Information Card
                VStack(alignment: .leading, spacing: 15) {
                    Text("Patient Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let patient = patient {
                        PatientInfoCard(patient: patient)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Hospital Information
                if let hospital = hospital {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Hospital Details")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HospitalInfoCard(hospital: hospital)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
                
                // Emergency Description Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Emergency Description")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $emergencyDescription)
                        .frame(height: 150)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Text("Describe your emergency condition...")
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                                .opacity(emergencyDescription.isEmpty ? 1 : 0),
                            alignment: .topLeading
                        )
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Book Emergency Button
                Button(action: bookEmergencyAppointment) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                        Text(isBookingEmergency ? "Booking..." : "Request Emergency Assistance")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canBookEmergency ? Color.red : Color.gray)
                    )
                    .foregroundColor(.white)
                }
                .disabled(!canBookEmergency || isBookingEmergency)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .alert("Emergency Assistance", isPresented: $showAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(alertMessage)
        }
        .task {
            await fetchUserAndHospitalDetails()
        }
    }
    
    private var canBookEmergency: Bool {
        patient != nil && hospital != nil && !emergencyDescription.isEmpty
    }
    
    private func fetchUserAndHospitalDetails() async {
        if let patientId = UUID(uuidString: UserDefaults.standard.string(forKey: "currentPatientId") ?? "") {
            do {
                patient = try await supabase.fetchPatientDetails(patientId: patientId)
                // Fetch nearest/default hospital - for now using the first hospital
                let hospitals = try await supabase.fetchHospitals()
                hospital = hospitals.first
            } catch {
                print("Error fetching details: \(error)")
            }
        }
    }
    
    private func bookEmergencyAppointment() {
        guard let patient = patient, let hospital = hospital else { return }
        
        isBookingEmergency = true
        
        Task {
            do {
                let emergencyAppointment = EmergencyAppointment(
                    id: UUID(),
                    hospitalId: hospital.id,
                    patientId: patient.id,
                    status: .scheduled,
                    description: emergencyDescription
                )
                
                try await supabase.createEmergencyAppointment(emergencyAppointment)
                alertMessage = "Emergency assistance request has been sent. The hospital will contact you shortly."
                showAlert = true
                isBookingEmergency = false
            } catch {
                print("Error booking emergency: \(error)")
                alertMessage = "Failed to book emergency appointment: \(error.localizedDescription)"
                showAlert = true
                isBookingEmergency = false
            }
        }
    }
}

// Helper Views
struct PatientInfoCard: View {
    let patient: Patient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EmergencyInfoRow(title: "Name", value: patient.fullname)
            EmergencyInfoRow(title: "Gender", value: patient.gender)
            EmergencyInfoRow(title: "Age", value: calculateAge(from: patient.dateofbirth))
            EmergencyInfoRow(title: "Contact", value: patient.contactno)
        }
    }
    
    private func calculateAge(from date: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return "\(ageComponents.year ?? 0) years"
    }
}

struct HospitalInfoCard: View {
    let hospital: Hospital
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EmergencyInfoRow(title: "Name", value: hospital.name)
            EmergencyInfoRow(title: "Address", value: hospital.address)
            EmergencyInfoRow(title: "Contact", value: hospital.mobile_number)
        }
    }
}

struct EmergencyInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationView {
        EmergencyAssistanceView()
    }
}
