import SwiftUI

struct AppointmentView: View {
    
    let appointments: [DummyAppointment] = [
        DummyAppointment(patientName: "Anubhav Dubey", visitType: "In Person Visit", description: "Frequent headaches, dizziness, and occasional shortness of breath.", dateTime: "March 20, 2025 | 10:55 am", status: "Upcoming"),
        DummyAppointment(patientName: "Neha Sharma", visitType: "Virtual Consultation", description: "Experiencing fatigue and mild fever.", dateTime: "March 21, 2025 | 12:30 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Rahul Verma", visitType: "In Person Visit", description: "Chest pain and irregular heartbeat concerns.", dateTime: "March 22, 2025 | 2:00 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Priya Singh", visitType: "Follow-Up", description: "Post-surgery recovery check-up.", dateTime: "March 23, 2025 | 4:15 pm", status: "Completed"),
        DummyAppointment(patientName: "Amit Patel", visitType: "In Person Visit", description: "High blood pressure management.", dateTime: "March 24, 2025 | 9:00 am", status: "Cancelled")
    ]
    
    let screenWidth = UIScreen.main.bounds.width
    
    @State private var selectedDate = Date() // ✅ Date Picker
    @State private var selectedAppointment: DummyAppointment? // ✅ Track selected appointment
    
    var body: some View {
        NavigationStack {
            VStack {
                // ✅ Date Picker to filter appointments
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                
                // Scrollable Vertical List of Appointments with Padding
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(appointments) { appointment in
                            upcomingAppointmentCard(appointment: appointment)
                                .onTapGesture {
                                    selectedAppointment = appointment
                                }
                        }
                    }
                    .padding(.horizontal, 16) // Added padding around the list
                    .padding(.top, 3) // Extra padding at the top
                }
            }
            .background(AppConfig.backgroundColor)
            .sheet(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: appointment) // ✅ Present as a modal
            }
        }
    }
    
    // ✅ Appointment Card View
    func upcomingAppointmentCard(appointment: DummyAppointment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(AppConfig.buttonColor)
                    .font(.title2)
                
                Text(appointment.patientName)
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
                
                Spacer()
                
                Text(appointment.status)
                    .font(.subheadline)
                    .foregroundColor(AppConfig.fontColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(statusBackgroundColor(appointment.status))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            Text(appointment.description)
                .font(.footnote)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .frame(height: 40)
                .lineLimit(2)

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
        .frame(width: screenWidth * 0.87)
        .frame(height: 150)
        .padding(.vertical, 8)
    }

    func statusBackgroundColor(_ status: String) -> Color {
        switch status {
        case "Upcoming": return AppConfig.yellowColor
        case "Completed": return AppConfig.greenColor
        case "Cancelled": return AppConfig.redColor
        default: return Color.gray
        }
    }
}

#Preview(body: {
    AppointmentView()
})
