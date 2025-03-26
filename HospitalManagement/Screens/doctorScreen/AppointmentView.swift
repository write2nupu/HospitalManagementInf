import SwiftUI

struct AppointmentView: View {
    
    let appointments: [DummyAppointment] = [
        DummyAppointment(patientName: "Anubhav Dubey", visitType: "In Person Visit", description: "Frequent headaches, dizziness, and occasional shortness of breath.", dateTime: "March 20, 2025 | 10:55 am", status: "Upcoming"),
        DummyAppointment(patientName: "Neha Sharma", visitType: "Virtual Consultation", description: "Experiencing fatigue and mild fever.", dateTime: "March 21, 2025 | 12:30 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Rahul Verma", visitType: "In Person Visit", description: "Chest pain and irregular heartbeat concerns.", dateTime: "March 22, 2025 | 2:00 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Priya Singh", visitType: "Follow-Up", description: "Post-surgery recovery check-up.", dateTime: "March 23, 2025 | 4:15 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Amit Patel", visitType: "In Person Visit", description: "High blood pressure management.", dateTime: "March 24, 2025 | 9:00 am", status: "Upcoming")
    ]
    
    let screenWidth = UIScreen.main.bounds.width
    
    @State private var selectedDate = Date() // ✅ Added Date Picker
    
    var body: some View {
        NavigationStack {
            VStack {
                // ✅ Date Picker to filter appointments
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                
                // ✅ Scrollable Vertical List of Appointments with Padding
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(appointments) { appointment in
                            NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                                upcomingAppointmentCard(appointment: appointment)
                            }
                        }
                    }
                    .padding(.horizontal, 16) // ✅ Added padding around the list
                    .padding(.top, 8) // ✅ Extra padding at the top
                }
            }
        }
    }
    
    // ✅ Appointment Card View
    func upcomingAppointmentCard(appointment: DummyAppointment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(appointment.patientName, systemImage: "person.fill")
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
                
                Spacer()
                
                Text(appointment.status)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(appointment.description)
                .font(.footnote)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            Spacer()
            
            HStack {
                Text(appointment.visitType)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.fontColor)
                
                Spacer()
                
                Text(appointment.dateTime)
                    .font(.footnote)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140) // ✅ Ensure card stretches to the full width
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color: AppConfig.shadowColor, radius: 6, x: 0, y: 8) // ✅ Bottom shadow
    }
}

#Preview(body: {
    AppointmentView()
})
