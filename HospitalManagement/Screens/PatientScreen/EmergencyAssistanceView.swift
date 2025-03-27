import SwiftUI

// MARK: - Emergency Assistance View
struct EmergencyAssistanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patientName = ""
    @State private var patientAge = ""
    @State private var emergencyDescription = ""
    @State private var isBookingEmergency = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emergency Assistance")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Provide necessary details for immediate medical help")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Patient Information Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Patient Details")
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Full Name", text: $patientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                        
                        TextField("Age", text: $patientAge)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                .padding(.horizontal)
                
                // Emergency Description Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Emergency Description")
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    TextEditor(text: $emergencyDescription)
                        .frame(height: 150)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .placeholder("Describe your medical emergency...", when: emergencyDescription.isEmpty)
                }
                .padding(.horizontal)
                
                // Book Emergency Button
                Button(action: {
                    bookEmergencyAssistance()
                }) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.white)
                        
                        Text(isBookingEmergency ? "Booking..." : "Book Emergency Assistance")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canBookEmergency ? Color.red : Color.gray)
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal)
                }
                .disabled(!canBookEmergency || isBookingEmergency)
            }
            .padding(.vertical)
        }
        .navigationBarBackButtonHidden(false)
    }
    
    // Computed property to check if emergency can be booked
    private var canBookEmergency: Bool {
        !patientName.isEmpty && 
        !patientAge.isEmpty && 
        !emergencyDescription.isEmpty
    }
    
    private func bookEmergencyAssistance() {
        guard canBookEmergency else { return }
        
        isBookingEmergency = true
        
        // Simulate async booking process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Prepare emergency appointment details
            let emergencyAppointmentDetails: [String: Any] = [
                "id": UUID().uuidString,
                "doctorName": "Emergency Assistance",
                "appointmentType": "Emergency",
                "patientName": patientName,
                "patientAge": patientAge,
                "emergencyDescription": emergencyDescription,
                "date": Date(),
                "timeSlot": "Immediate",
                "status": "Booked",
                "timestamp": Date()
            ]
            
            // Save emergency appointment details to UserDefaults
            var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
            savedAppointments.append(emergencyAppointmentDetails)
            UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
            
            // Reset and dismiss
            isBookingEmergency = false
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EmergencyAssistanceView()
    }
} 