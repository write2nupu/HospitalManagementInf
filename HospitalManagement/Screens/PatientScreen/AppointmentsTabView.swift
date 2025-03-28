import SwiftUI

struct AppointmentsTabView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]], !savedAppointments.isEmpty {
                    AppointmentListView(savedAppointments: .init(
                        get: { UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? [] },
                        set: { UserDefaults.standard.set($0, forKey: "savedAppointments") }
                    ))
                    .padding(.top, 50) // Add space at the top for the sticky header
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
                    .padding(.top, 50) // Add space at the top for the sticky header
                }
            }
            
            // Sticky header for Appointments tab
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
}

#Preview {
    NavigationView {
        AppointmentsTabView()
    }
} 