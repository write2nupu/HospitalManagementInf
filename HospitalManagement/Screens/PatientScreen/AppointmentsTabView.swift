import SwiftUI

struct AppointmentsTabView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]], !savedAppointments.isEmpty {
                    VStack(spacing: 0) {
                        // Fixed header title for "UPCOMING APPOINTMENTS"
                        Text("UPCOMING APPOINTMENTS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color(.systemGroupedBackground))
                        
                        // List of appointments with padding to account for the sticky header
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(savedAppointments.indices, id: \.self) { index in
                                    VStack(spacing: 0) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(savedAppointments[index]["doctorName"] as? String ?? "")
                                                    .font(.headline)
                                                
                                                HStack(spacing: 10) {
                                                    Image(systemName: "calendar")
                                                        .foregroundColor(.gray)
                                                    Text(formatAppointmentDate(savedAppointments[index]["date"]))
                                                        .font(.subheadline)
                                                    
                                                    Image(systemName: "clock")
                                                        .foregroundColor(.gray)
                                                    Text(savedAppointments[index]["timeSlot"] as? String ?? "")
                                                        .font(.subheadline)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Text(savedAppointments[index]["appointmentType"] as? String ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(
                                                    (savedAppointments[index]["appointmentType"] as? String) == "Emergency" ? 
                                                        .red : .mint
                                                )
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .background(Color(.systemBackground))
                                        
                                        Divider()
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            deleteAppointment(at: IndexSet(integer: index))
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("No Appointments")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Book your first appointment to see it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: DepartmentListView()) {
                            Text("Book Appointment")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.mint)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(.top, 50) // Add space at the top for the sticky header
            
            // Sticky header
            VStack(spacing: 0) {
                Text("Appointments")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color(.systemBackground))
                
                Divider()
            }
            .background(Color(.systemBackground))
            .zIndex(1) // Ensure header appears on top
        }
    }
    
    // Comprehensive date formatting method
    private func formatAppointmentDate(_ dateObj: Any?) -> String {
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
    
    // Function to delete an appointment
    private func deleteAppointment(at offsets: IndexSet) {
        var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        savedAppointments.remove(atOffsets: offsets)
        UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
    }
}

// MARK: - Preview
#Preview {
    AppointmentsTabView()
} 