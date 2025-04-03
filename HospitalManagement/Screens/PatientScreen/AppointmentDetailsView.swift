import SwiftUI

struct AppointmentDetailsView: View {
    let appointmentDetails: [String: Any]
    
    // Static method for date formatting
    private static func formatAppointmentDate(_ dateObj: Any?) -> String {
        // Create a date formatter
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        // Simplified date extraction
        func extractDate(_ obj: Any?) -> Date? {
            // Direct Date casting
            if let date = obj as? Date { return date }
            
            // Dictionary date extraction
            if let dict = obj as? [String: Any] {
                let keys = ["date", "timestamp", "createdAt"]
                for key in keys {
                    if let date = dict[key] as? Date { return date }
                }
            }
            
            return nil
        }
        
        // Extract and format date
        guard let date = extractDate(dateObj) else { return "N/A" }
        return formatter.string(from: date)
    }
    
    var appointmentType: String {
        appointmentDetails["appointmentType"] as? String ?? ""
    }
    
    var doctorName: String {
        appointmentDetails["doctorName"] as? String ?? "Appointment"
    }
    
    var appointmentIcon: String {
        appointmentType == "Emergency" ? "cross.case.fill" : "calendar.badge.plus"
    }
    
    var appointmentIconColor: Color {
        appointmentType == "Emergency" ? .red : .mint
    }
    
    var appointmentBackgroundColor: Color {
        appointmentType == "Emergency" ? Color.red.opacity(0.1) : AppConfig.buttonColor
    }
    
    var appointmentTextColor: Color {
        appointmentType == "Emergency" ? .red : .mint
    }
    
    var emergencyDescription: String? {
        appointmentDetails["emergencyDescription"] as? String
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Appointment Type Header
                VStack(alignment: .leading, spacing: 15) {
                    HStack(spacing: 15) {
                        Image(systemName: appointmentIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding()
                            .background(appointmentIconColor)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(doctorName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(appointmentTextColor)
                            
                            Text(appointmentType)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(appointmentBackgroundColor)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Appointment Details Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Appointment Details")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.fontColor)
                    
                    VStack(spacing: 15) {
                        DetailRow1(icon: "calendar", title: "Date", value: Self.formatAppointmentDate(appointmentDetails["date"]))
                        Divider()
                        DetailRow1(icon: "clock", title: "Time Slot", value: appointmentDetails["timeSlot"] as? String ?? "N/A")
                        
                        if let patientName = appointmentDetails["patientName"] as? String {
                            Divider()
                            DetailRow1(icon: "person", title: "Patient Name", value: patientName)
                        }
                        
                        if let patientAge = appointmentDetails["patientAge"] as? String {
                            Divider()
                            DetailRow1(icon: "number", title: "Patient Age", value: patientAge)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                .padding(.horizontal)
                
                // Emergency Description (if applicable)
                if let emergencyDescription = emergencyDescription, !emergencyDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Emergency Description")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                        
                        Text(emergencyDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppConfig.backgroundColor)
    }
}


// MARK: - Detail Row View
struct DetailRow1: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(AppConfig.buttonColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(AppConfig.fontColor)
            }
            
            Spacer()
        }
    }
}
