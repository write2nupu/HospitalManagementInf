import SwiftUI


//To be deleted
struct DummyAppointment: Identifiable {
    let id = UUID()
    let patientName: String
    let visitType: String
    let description: String
    let dateTime: String
    let status: String
}

struct DoctorDashBoard: View {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    @State private var selectedAppointment: DummyAppointment? // ✅ Track selected appointment
    
    // ✅ Dummy data for appointments to be deleted when data fetched from db
    let appointments: [DummyAppointment] = [
        DummyAppointment(patientName: "Anubhav Dubey", visitType: "In Person Visit", description: "Frequent headaches, dizziness, and occasional shortness of breath.", dateTime: "March 20, 2025 | 10:55 am", status: "Upcoming"),
        DummyAppointment(patientName: "Neha Sharma", visitType: "Virtual Consultation", description: "Experiencing fatigue and mild fever.", dateTime: "March 21, 2025 | 12:30 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Rahul Verma", visitType: "In Person Visit", description: "Chest pain and irregular heartbeat concerns.", dateTime: "March 22, 2025 | 2:00 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Priya Singh", visitType: "Follow-Up", description: "Post-surgery recovery check-up.", dateTime: "March 23, 2025 | 4:15 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Amit Patel", visitType: "In Person Visit", description: "High blood pressure management.", dateTime: "March 24, 2025 | 9:00 am", status: "Upcoming")
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
                    
                    Text("Urgent Need of psychologist")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading)
                .padding()
                .background(AppConfig.cardColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(color: AppConfig.shadowColor, radius: 6, x: 0, y: 8) // ✅ Bottom shadow
                
                
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
                    LazyHStack(spacing: 16) { // Use LazyHStack for better performance
                        ForEach(appointments) { appointment in
                            upcomingAppointmentCard(appointment: appointment)
                                .frame(width: screenWidth * 0.87) // Ensure fixed width for each card
                                .frame(height: 150)
                                .padding(.vertical, 8) // Add vertical padding for spacing
                                .onTapGesture {
                                    selectedAppointment = appointment
                                }
                        }
                    }
                    .padding(.horizontal, 16) // Proper left & right padding for alignment
                }

            }
            .padding(.top, 10)
        }
        .background(AppConfig.backgroundColor.ignoresSafeArea())
        .frame(maxHeight: screenHeight)
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentDetailView(appointment: appointment) // ✅ Present modal when tapped
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
    func upcomingAppointmentCard(appointment: DummyAppointment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                //  Patient Icon
                Image(systemName: "person.fill")
                    .foregroundColor(AppConfig.buttonColor)
                    .font(.title2)
                
                // Patient Name
                Text(appointment.patientName)
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
                
                
                
                Spacer()
                
                // Appointment Status (with rounded background)
                Text(appointment.status)
                    .font(.subheadline)
                    .foregroundColor(AppConfig.fontColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusBackgroundColor(appointment.status))
                    .clipShape(RoundedRectangle(cornerRadius: 15))

            }
            
            // Appointment Description
            Text(appointment.description)
                .font(.footnote)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .frame(height: 40) // Ensures consistent height
                .lineLimit(2) // Limits text to 2 lines to avoid overflow

            
            // Visit Type & Date
            HStack {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppConfig.buttonColor)
                    Text(appointment.visitType)
                        .font(.footnote)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppConfig.buttonColor)
                    Text(appointment.dateTime)
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
        .frame(width: screenWidth * 0.87) // Fixed width
        .frame(height: 150) // Adjust height
        .padding(.vertical, 8) // Add spacing between cards
    }

    // 🎨 Function to dynamically set background color for status
    func statusBackgroundColor(_ status: String) -> Color {
        switch status {
        case "Upcoming": return AppConfig.yellowColor
        case "Completed": return AppConfig.greenColor
        case "Cancelled": return AppConfig.redColor
        default: return Color.gray
        }
    }

}


#Preview {
    DoctorDashBoard()
}
