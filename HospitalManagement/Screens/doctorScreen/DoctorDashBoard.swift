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
                    HStack(spacing: 16) {
                        ForEach(appointments) { appointment in
                            upcomingAppointmentCard(appointment: appointment)
                                .frame(width: screenWidth * 0.8)
                                .onTapGesture {
                                    selectedAppointment = appointment // ✅ Open details when tapped
                                }
                        }
                    }
                    .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(appointment.patientName, systemImage: "person.fill")
                    .font(.headline)
                
                Spacer()
                
                Text(appointment.status)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(appointment.description)
                .font(.footnote)
                .foregroundColor(.black)
            
            Spacer()
            
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
        .frame(width: screenWidth * 0.8)
        .frame(minHeight: 140)
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color: AppConfig.shadowColor, radius: 6, x: 0, y: 8) // ✅ Bottom shadow
        .padding(.vertical, 8) // ✅ Added vertical margin
    }
    
}


#Preview {
    DoctorDashBoard()
}
