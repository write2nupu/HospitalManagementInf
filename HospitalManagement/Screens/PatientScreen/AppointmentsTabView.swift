import SwiftUI

struct AppointmentsTabView: View {
    var body: some View {
        VStack(spacing: 0) {
            if let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]], !savedAppointments.isEmpty {
                AppointmentListView(savedAppointments: .init(
                    get: { UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? [] },
                    set: { UserDefaults.standard.set($0, forKey: "savedAppointments") }
                ))
            } else {
                VStack(spacing: 25) {
                    Spacer()
                    
                    Image(systemName: "calendar.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray.opacity(0.5))
                    
                    VStack(spacing: 12) {
                        Text("No Appointments")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Book your first appointment to see it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    NavigationLink(destination: DepartmentListView()) {
                        Text("Book Appointment")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.mint)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

#Preview {
    NavigationView {
        AppointmentsTabView()
    }
}
