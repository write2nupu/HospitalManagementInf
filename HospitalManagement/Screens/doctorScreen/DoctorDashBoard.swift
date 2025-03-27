import SwiftUI

struct DoctorDashBoard: View {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    @State private var selectedAppointment: Appointment?
    
    let appointments: [Appointment] = [
        // Get Data here
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // **Doctor Info Header**
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cardiologist")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Apollo Hospital")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("12 years exp.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -10)
                
                // **Emergency Alert Section**
                VStack(alignment: .leading, spacing: 5) {
                    Text("Emergency")
                        .font(.title)
                        .fontWeight(.regular)
                    
                    Text("Urgent Need of Psychologist")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading)
                .padding()
                .background(AppConfig.cardColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(color: AppConfig.shadowColor, radius: 6, x: 0, y: 8)
                
                // **Appointments & Patients Stats**
                HStack(spacing: 16) {
                    statCard(title: "Appointments Completed", value: "17")
                    statCard(title: "Patients Handling", value: "23")
                }
                .padding(.horizontal)
                
                // **Upcoming Appointments (Horizontal Scroll)**
                Text("Upcoming Appointments")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(appointments) { appointment in
                            upcomingAppointmentCard(appointment: appointment)
                                .frame(width: screenWidth * 0.87)
                                .frame(height: 150)
                                .padding(.vertical, 8)
                                .onTapGesture {
                                    selectedAppointment = appointment
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 10)
        }
        .background(AppConfig.backgroundColor.ignoresSafeArea())
        .frame(maxHeight: screenHeight)
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentDetailView(appointment: appointment)
        }
    }
    
    // **Stat Card Component**
    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            Spacer()
            Text(title)
                .font(.footnote)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: (screenWidth - 40) / 2, minHeight: 70)
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color: AppConfig.shadowColor, radius: 5, x: 0, y: 4)
    }
    
    // **Upcoming Appointment Card**
    func upcomingAppointmentCard(appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(AppConfig.buttonColor)
                    .font(.title2)
                
                Spacer()
                
                Text(appointment.status.rawValue) // ✅ Convert enum to String
                    .font(.subheadline)
                    .foregroundColor(AppConfig.fontColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            // Visit Type & Date
            HStack {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppConfig.buttonColor)
                    Text(appointment.type.rawValue) // ✅ Convert enum to String
                        .font(.footnote)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppConfig.buttonColor)
                    Text(formatDate(appointment.date)) // ✅ Convert Date to String
                        .font(.footnote)
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor.opacity(0.3), radius: 8, x: 0, y: 6)
        )
        .frame(width: screenWidth * 0.87)
        .frame(height: 150)
        .padding(.vertical, 8)
    }

    // ✅ Format Date Function
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy - h:mm a" // Example: "Mar 26, 2025 - 10:30 AM"
        return formatter.string(from: date)
    }
}

#Preview {
    DoctorDashBoard()
}
