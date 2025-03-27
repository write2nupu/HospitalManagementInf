import SwiftUI

struct DoctorDashBoard: View {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    @StateObject private var supabase = SupabaseController()
    @State private var selectedAppointment: Appointment?
    @State private var doctorProfile: Doctor?
    @State private var department: Department?
    @State private var hospital: Hospital?
    @State private var appointments: [Appointment] = []
    @State private var completedAppointments = 0
    @State private var activePatients = 0
    @State private var isLoading = true
    @State private var error: Error?
    @AppStorage("currentUserId") private var currentUserId: String = ""
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack {
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await loadData()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // **Doctor Info Header**
                    if let doctor = doctorProfile {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(department?.name ?? "Department")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text(hospital?.name ?? "Hospital")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(doctor.experience) years exp.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, -10)
                    }
                    
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
                        statCard(title: "Appointments Completed", value: "\(completedAppointments)")
                        statCard(title: "Patients Handling", value: "\(activePatients)")
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
        }
        .background(AppConfig.backgroundColor.ignoresSafeArea())
        .frame(maxHeight: screenHeight)
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentDetailView(appointment: appointment)
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            guard let doctorId = UUID(uuidString: currentUserId) else {
                self.error = NSError(domain: "", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Invalid doctor ID"])
                isLoading = false
                return
            }
            
            async let profileTask = supabase.fetchDoctorProfile(doctorId: doctorId)
            async let appointmentsTask = supabase.fetchDoctorAppointments(doctorId: doctorId)
            async let statsTask = supabase.fetchDoctorStats(doctorId: doctorId)
            
            let (profile, appointments, stats) = try await (profileTask, appointmentsTask, statsTask)
            
            self.doctorProfile = profile
            self.appointments = appointments
            self.completedAppointments = stats.completedAppointments
            self.activePatients = stats.activePatients
            
            // Fetch department details if we have a doctor profile
            if let departmentId = profile.department_id {
                self.department = try await supabase.fetchDepartmentDetails(departmentId: departmentId)
            }
            
            // Fetch hospital details if we have a doctor profile
            if let hospitalId = profile.hospital_id {
                let hospitals: [Hospital] = try await supabase.client
                    .from("Hospital")
                    .select()
                    .eq("id", value: hospitalId.uuidString)
                    .execute()
                    .value
                self.hospital = hospitals.first
            }
        } catch {
            self.error = error
            print("Error loading data:", error)
        }
        
        isLoading = false
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
