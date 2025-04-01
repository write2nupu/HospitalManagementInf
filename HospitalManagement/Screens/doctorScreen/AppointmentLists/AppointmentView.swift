import SwiftUI

struct AppointmentView: View {
    @StateObject private var supabase = SupabaseController()
    @State private var appointments: [Appointment] = []
    @State private var selectedDate = Date()
    @State private var selectedAppointment: Appointment?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var patientNames: [UUID: String] = [:]
    @AppStorage("currentUserId") private var currentUserId: String = ""
    
    let screenWidth = UIScreen.main.bounds.width
    
    var filteredAppointments: [Appointment] {
        appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .onChange(of: selectedDate) { 
                        Task {
                            await loadAppointments()
                        }
                    }
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack {
                        Text("Error loading appointments")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await loadAppointments()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                        .padding(.horizontal, 18)
                        .padding(.top, 3)
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
            .sheet(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: appointment)
            }
            .task {
                await loadAppointments()
            }
        }
    }
    
    private func loadAppointments() async {
        isLoading = true
        error = nil
        
        do {
            guard let doctorId = UUID(uuidString: currentUserId) else {
                self.error = NSError(domain: "", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Invalid doctor ID"])
                isLoading = false
                return
            }
            
            appointments = try await supabase.fetchDoctorAppointments(doctorId: doctorId)
            
            // Fetch patient names for all appointments
            for appointment in appointments {
                if patientNames[appointment.patientId] == nil {
                    do {
                        let patient = try await supabase.fetchPatientById(patientId: appointment.patientId)
                        patientNames[appointment.patientId] = patient.fullname
                    } catch {
                        print("Error fetching patient name:", error)
                        patientNames[appointment.patientId] = "Unknown Patient"
                    }
                }
            }
        } catch {
            self.error = error
            print("Error loading appointments:", error)
        }
        
        isLoading = false
    }
    
    // ✅ Appointment Card View
    func upcomingAppointmentCard(appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(AppConfig.buttonColor)
                    .font(.title2)
                
                Text(patientNames[appointment.patientId] ?? "Loading...")
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
        .frame(width: screenWidth * 0.95)
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

#Preview {
    AppointmentView()
}
