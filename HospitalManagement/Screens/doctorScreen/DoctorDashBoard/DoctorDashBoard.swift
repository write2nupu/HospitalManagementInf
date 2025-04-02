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
    @State private var patientNames: [UUID: String] = [:]
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var refreshTimer: Timer?
    @State private var isViewActive = true
    @State private var loadDataTask: Task<Void, Never>?
    
//    VARIABLE TO store Doctor Leave
    @State private var docLeave: Leave? = Leave(id: UUID(), doctorId: UUID(), hospitalId: UUID(), type: .casualLeave, reason: "mera man", startDate: Date(), endDate: Date(), status: .pending)
    
    // Computed property for upcoming appointments
    private var upcomingAppointments: [Appointment] {
        let now = Date()
        return appointments
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
    }
    
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
                            await startLoadingData()
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
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("Emergency")
//                            .font(.title)
//                            .fontWeight(.regular)
//                        
//                        Text("Urgent Need of Psychologist")
//                            .font(.subheadline)
//                            .foregroundColor(.black)
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading)
//                    .padding()
//                    .background(AppConfig.cardColor)
//                    .cornerRadius(12)
//                    .padding(.horizontal)
//                    .shadow(color: AppConfig.shadowColor, radius: 6, x: 0, y: 8)
                    
                    // **Appointments & Patients Stats**
                    HStack(spacing: 16) {
                        statCard(title: "Appointments Completed", value: "\(completedAppointments)")
                        statCard(title: "Patients Handling", value: "\(activePatients)")
                    }
                    .padding(.horizontal)
                    
                    if let leave = docLeave{
                        Text("Your leave")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LeaveStatusCard(leave: leave)
                            .padding()
                    }
                    
                    // **Upcoming Appointments Section**
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Upcoming Appointments")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if !upcomingAppointments.isEmpty {
                                Text("\(upcomingAppointments.count) upcoming")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        
                        if upcomingAppointments.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No upcoming appointments")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 12) {
                                    ForEach(upcomingAppointments) { appointment in
                                        upcomingAppointmentCard(appointment: appointment)
                                            .onTapGesture {
                                                selectedAppointment = appointment
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
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
        .onAppear {
            isViewActive = true
            startLoadingData()
        }
        .onDisappear {
            isViewActive = false
            cancelLoadingTask()
            stopRefreshTimer()
        }
    }
    
    private func startLoadingData() {
        cancelLoadingTask()
        loadDataTask = Task {
            await loadData()
            
            // Start refresh timer after initial load
            if isViewActive {
                startRefreshTimer()
            }
        }
    }
    
    private func cancelLoadingTask() {
        loadDataTask?.cancel()
        loadDataTask = nil
    }
    
    private func startRefreshTimer() {
        stopRefreshTimer()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            if isViewActive {
                startLoadingData()
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func loadData() async {
        guard !Task.isCancelled && isViewActive else { return }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            guard let doctorId = UUID(uuidString: currentUserId) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid doctor ID"])
            }
            
            // Create individual tasks for concurrent fetching
            async let profileTask = supabase.fetchDoctorProfile(doctorId: doctorId)
            async let appointmentsTask = supabase.fetchDoctorAppointments(doctorId: doctorId)
            async let statsTask = supabase.fetchDoctorStats(doctorId: doctorId)
            
            // Wait for all tasks to complete
            guard !Task.isCancelled else { return }
            let (profile, fetchedAppointments, stats) = try await (profileTask, appointmentsTask, statsTask)
            
            guard !Task.isCancelled && isViewActive else { return }
            
            // Update UI on main thread
            await MainActor.run {
                doctorProfile = profile
                appointments = fetchedAppointments
                completedAppointments = stats.completedAppointments
                activePatients = stats.activePatients
            }
            
            // Fetch additional details if needed
            if let departmentId = profile.department_id {
                guard !Task.isCancelled else { return }
                if let deptDetails = await supabase.fetchDepartmentDetails(departmentId: departmentId) {
                    if isViewActive {
                        await MainActor.run { department = deptDetails }
                    }
                }
            }
            
            if let hospitalId = profile.hospital_id {
                guard !Task.isCancelled else { return }
                let hospitalDetails = try await supabase.fetchHospitalById(hospitalId: hospitalId)
                if isViewActive {
                    await MainActor.run { hospital = hospitalDetails }
                }
            }
            
            // Fetch patient names
            var updatedNames: [UUID: String] = [:]
            for appointment in fetchedAppointments {
                guard !Task.isCancelled else { return }
                if patientNames[appointment.patientId] == nil {
                    do {
                        let patient = try await supabase.fetchPatientById(patientId: appointment.patientId)
                        updatedNames[appointment.patientId] = patient.fullname
                    } catch {
                        print("Error fetching patient name:", error)
                        updatedNames[appointment.patientId] = "Unknown Patient"
                    }
                }
            }
            
            guard !Task.isCancelled && isViewActive else { return }
            await MainActor.run {
                for (id, name) in updatedNames {
                    patientNames[id] = name
                }
            }
            
        } catch {
            guard !Task.isCancelled && isViewActive else { return }
            await MainActor.run {
                self.error = error
                print("Error loading data:", error)
            }
        }
        
        guard !Task.isCancelled && isViewActive else { return }
        await MainActor.run {
            isLoading = false
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
    
    // Updated appointment card with better UI
    func upcomingAppointmentCard(appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                // Patient Icon with Background
                Circle()
                    .fill(AppConfig.buttonColor.opacity(0.1))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(AppConfig.buttonColor)
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(patientNames[appointment.patientId] ?? "Loading...")
                        .font(.headline)
                    
                    Text(appointment.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Status Badge
                Text(appointment.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(statusColor(for: appointment.status).opacity(0.1))
                    )
                    .foregroundColor(statusColor(for: appointment.status))
            }
            
            Divider()
            
            // Date and Time with Icons
            HStack(spacing: 16) {
                // Date
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppConfig.buttonColor)
                    Text(formatDate(appointment.date, format: "MMM d, yyyy"))
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Time
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppConfig.buttonColor)
                    Text(formatDate(appointment.date, format: "h:mm a"))
                        .font(.subheadline)
                }
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Helper function to format date with custom format
    func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // Helper function to determine status color
    func statusColor(for status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    DoctorDashBoard()
}
