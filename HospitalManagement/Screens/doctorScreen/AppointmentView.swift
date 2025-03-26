import SwiftUI



struct AppointmentView: View {
    
    let appointments: [DummyAppointment] = [
        DummyAppointment(patientName: "Anubhav Dubey", visitType: "In Person Visit", description: "Frequent headaches, dizziness, and occasional shortness of breath.", dateTime: "March 20, 2025 | 10:55 am", status: "Upcoming"),
        DummyAppointment(patientName: "Neha Sharma", visitType: "Virtual Consultation", description: "Experiencing fatigue and mild fever.", dateTime: "March 21, 2025 | 12:30 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Rahul Verma", visitType: "In Person Visit", description: "Chest pain and irregular heartbeat concerns.", dateTime: "March 22, 2025 | 2:00 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Priya Singh", visitType: "Follow-Up", description: "Post-surgery recovery check-up.", dateTime: "March 23, 2025 | 4:15 pm", status: "Upcoming"),
        DummyAppointment(patientName: "Amit Patel", visitType: "In Person Visit", description: "High blood pressure management.", dateTime: "March 24, 2025 | 9:00 am", status: "Upcoming")
    ]
    
    @State private var selectedAppointment: DummyAppointment? // ✅ Track selected appointment
    @State private var selectedDate = Date() // ✅ Added Date Picker

    var body: some View {
        VStack {
            // ✅ Date Picker to filter appointments
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
            
            // ✅ Scrollable Vertical List of Appointments
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(appointments) { appointment in
                        upcomingAppointmentCard(appointment: appointment)
                            .onTapGesture {
                                selectedAppointment = appointment // ✅ Open details when tapped
                            }
                    }
                }
            }
        }
        .navigationTitle("Appointments")
    }
    
    // ✅ Appointment Card View
    func upcomingAppointmentCard(appointment: DummyAppointment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(appointment.patientName, systemImage: "person.fill")
                    .font(.headline)
                
                Spacer()
                
                Text(appointment.status)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(appointment.description)
                .font(.footnote)
                .foregroundColor(.black)
            
            HStack {
                Text(appointment.visitType)
                    .font(.footnote)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(appointment.dateTime)
                    .font(.footnote)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(Color.white) // ✅ Card Background
        .cornerRadius(12)
        .shadow(color: Color.gray.opacity(0.4), radius: 6, x: 0, y: 4) // ✅ Light Shadow
        .padding(.horizontal)
    }
}

// ✅ Preview
struct AppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentView()
    }
}
