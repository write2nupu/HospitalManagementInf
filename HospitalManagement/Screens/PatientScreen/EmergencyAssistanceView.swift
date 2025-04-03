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
            VStack(spacing: 20) {
                // Emergency Header
                emergencyHeader
                
                // Main Content
                VStack(spacing: 16) {
                    // Patient Card
                    if let patient = patient {
                        patientCard(patient)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Hospital Card
                    if let hospital = hospital {
                        hospitalCard(hospital)
                    }
                    
                    // Emergency Description
                    emergencyDescriptionSection
                    
                    // Request Button
                    requestButton
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Emergency Assistance", isPresented: $showAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(alertMessage)
        }
        .task {
            await fetchUserAndHospitalDetails()
        }
    }
    
    private var emergencyHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .padding(.bottom, 4)
            
            Text("Emergency Assistance")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Request immediate medical attention")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    private func patientCard(_ patient: Patient) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(AppConfig.buttonColor)
                Text("Patient Information")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                infoRow(title: "Name", value: patient.fullname)
                infoRow(title: "Gender", value: patient.gender)
                infoRow(title: "Age", value: calculateAge(from: patient.dateofbirth))
                infoRow(title: "Contact", value: patient.contactno)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func hospitalCard(_ hospital: Hospital) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(AppConfig.buttonColor)
                Text("Hospital Information")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                infoRow(title: "Name", value: hospital.name)
                infoRow(title: "Address", value: hospital.address)
                infoRow(title: "Contact", value: hospital.mobile_number)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var emergencyDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(AppConfig.buttonColor)
                Text("Emergency Description")
                    .font(.headline)
            }
            
            ZStack(alignment: .topLeading) {
                if emergencyDescription.isEmpty {
                    Text("Describe your emergency condition...")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.leading, 4)
                        .padding(.top, 8)
                }
                
                TextEditor(text: $emergencyDescription)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppConfig.shadowColor.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var requestButton: some View {
        Button(action: bookEmergencyAppointment) {
            HStack {
                if isBookingEmergency {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "cross.case.fill")
                    Text("Request Emergency Assistance")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canBookEmergency ? Color.red : Color.gray.opacity(0.3))
            )
            .foregroundColor(.white)
        }
        .disabled(!canBookEmergency || isBookingEmergency)
        .padding(.vertical, 8)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
    }
    
    private var canBookEmergency: Bool {
        patient != nil && hospital != nil && !emergencyDescription.isEmpty
    }
    
    private func calculateAge(from date: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return "\(ageComponents.year ?? 0) years"
    }
    
    private func fetchUserAndHospitalDetails() async {
        if let patientId = UUID(uuidString: UserDefaults.standard.string(forKey: "currentPatientId") ?? "") {
            do {
                patient = try await supabase.fetchPatientDetails(patientId: patientId)
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

#Preview {
    NavigationView {
        EmergencyAssistanceView()
    }
}
