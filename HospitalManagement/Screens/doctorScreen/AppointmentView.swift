import SwiftUI

struct AppointmentView: View {
    
    let appointments: [Appointment] = [
        Appointment(
            id: UUID(),
            patientId: UUID(),
            doctorId: UUID(),
            date: Date(),
            status: .scheduled,
            createdAt: Date(),
            type: .Consultation
        ),

    ]
    
    let screenWidth = UIScreen.main.bounds.width
    
    @State private var selectedDate = Date() // ✅ Date Picker
    @State private var selectedAppointment: Appointment? // ✅ Track selected appointment
    
    var filteredAppointments: [Appointment] {
        appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // ✅ Date Picker to filter appointments
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)

                // Scrollable List of Appointments
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        if filteredAppointments.isEmpty {
                            Text("No appointments on this date.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(filteredAppointments) { appointment in
                                upcomingAppointmentCard(appointment: appointment)
                                    .onTapGesture {
                                        selectedAppointment = appointment
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 3)
                }
            }
            .background(Color(UIColor.systemGray6))
            .sheet(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: filteredAppointments[0]) // ✅ Pass correct instance
            }
        }
    }
    
    // ✅ Appointment Card View
    func upcomingAppointmentCard(appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(AppConfig.buttonColor)
                    .font(.title2)
                
                Text("Patient ID: \(appointment.patientId.uuidString.prefix(6))") // Dummy representation should be replace by patient Name
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(appointment.status.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            Text("Type: \(appointment.type.rawValue)")
                .font(.footnote)
                .foregroundColor(.black)

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppConfig.buttonColor)
                Text(formatDate(appointment.date))
                    .font(.footnote)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .foregroundColor(AppConfig.buttonColor)
                Text(formatTime(appointment.date))
                    .font(.footnote)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 6)
        )
        .frame(width: screenWidth * 0.87)
        .frame(height: 150)
        .padding(.vertical, 8)
    }
    
    

    // Function to format Date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Function to format Time
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Preview
struct AppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentView()
    }
}
