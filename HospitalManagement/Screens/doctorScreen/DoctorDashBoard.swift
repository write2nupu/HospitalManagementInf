import SwiftUI

struct DoctorDashBoard: View {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    @State private var showProfile = false
    
    var doctor: Doctor?
    
    var dynamicTitle: String {
        return "Hi, \(doctor?.full_name.components(separatedBy: " ").first ?? "Doctor")"
    }
    
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
    @State private var docLeave: Leave? = nil
    
    @State private var showCancelledAlert = false
    
    // Computed property for upcoming appointments
    private var upcomingAppointments: [Appointment] {
        let now = Date()
        let calendar = Calendar.current
        let sevenDaysFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
        
        return appointments
            .filter { appointment in
                // Filter appointments that are in the future but within next 7 days
                appointment.date > now && appointment.date <= sevenDaysFromNow
            }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
            .frame(height: 0)
            
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
        .background(AppConfig.backgroundColor)
//        .frame(maxHeight: screenHeight)
        .sheet(item: $selectedAppointment) { appointment in
            if appointment.status != .cancelled {
                AppointmentDetailView(
                    appointment: appointment,
                    onStatusUpdate: { newStatus in
                        Task {
                            // Update local state immediately
                            await MainActor.run {
                                if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                                    appointments[index].status = newStatus
                                }
                            }
                            // Then refresh data from server
                            await refreshAppointmentsAndStats()
                        }
                    }
                )
            }
        }
        .alert("Cancelled Appointment", isPresented: $showCancelledAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This appointment has been cancelled and cannot be viewed or modified.")
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
        .navigationTitle(dynamicTitle)
        .toolbar {
           ToolbarItem(placement: .navigationBarTrailing) {
               Button(action: {
                   showProfile = true
               }) {
                   Image(systemName: "person.crop.circle.fill")
                       .resizable()
                       .frame(width: 40, height: 40)
                       .foregroundColor(AppConfig.buttonColor)
                       .padding(.top, 10)
               }
           }
        }
        .sheet(isPresented: $showProfile) {
           if let doctor = doctor {
               DoctorProfileView(doctor: doctor)
           }
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
        // Reduce refresh interval to 15 seconds for more responsive updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            if isViewActive {
                Task {
                    // Only fetch appointments and stats during refresh to reduce load
                    await refreshAppointmentsAndStats()
                }
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
            
            // Load profile first
            guard !Task.isCancelled else { return }
            let profile = try await supabase.fetchDoctorProfile(doctorId: doctorId)
            
            // Load appointments with a limit
            guard !Task.isCancelled else { return }
            let fetchedAppointments = try await supabase.fetchDoctorAppointments(doctorId: doctorId)
            
            // Load stats
            guard !Task.isCancelled else { return }
            let stats = try await supabase.fetchDoctorStats(doctorId: doctorId)
            
            // Load leave info
            guard !Task.isCancelled else { return }
            let latestLeave = try await supabase.fetchPendingLeave(doctorId: doctorId)
            
            guard !Task.isCancelled && isViewActive else { return }
            
            // Update UI on main thread with basic info
            await MainActor.run {
                doctorProfile = profile
                appointments = fetchedAppointments
                completedAppointments = stats.completedAppointments
                activePatients = stats.activePatients
                docLeave = latestLeave
                isLoading = false
            }
            
            // Load additional details in background
            Task {
                do {
                    // Fetch department details if needed
                    if let departmentId = profile.department_id {
                        if let deptDetails = await supabase.fetchDepartmentDetails(departmentId: departmentId) {
                            await MainActor.run {
                                department = deptDetails
                            }
                        }
                    }
                    
                    // Fetch hospital details if needed
                    if let hospitalId = profile.hospital_id {
                        if let hospitalDetails = try? await supabase.fetchHospitalById(hospitalId: hospitalId) {
                            await MainActor.run {
                                hospital = hospitalDetails
                            }
                        }
                    }
                    
                    // Fetch patient names in batches
                    for appointment in fetchedAppointments {
                        if patientNames[appointment.patientId] == nil {
                            do {
                                let patient = try await supabase.fetchPatientById(patientId: appointment.patientId)
                                await MainActor.run {
                                    patientNames[appointment.patientId] = patient?.fullname
                                }
                            } catch {
                                print("Error fetching patient name for ID \(appointment.patientId): \(error)")
                                await MainActor.run {
                                    patientNames[appointment.patientId] = "Unknown Patient"
                                }
                            }
                        }
                    }
                }
            }
            
        } catch {
            guard !Task.isCancelled && isViewActive else { return }
            await MainActor.run {
                self.error = error
                isLoading = false
                print("Error loading data:", error)
            }
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
                .font(.caption)
//                .foregroundColor(.black)
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
        .background(AppConfig.cardColor)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onTapGesture {
            if appointment.status == .cancelled {
                showCancelledAlert = true
            } else {
                selectedAppointment = appointment
            }
        }
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
    
    // Add new function for lightweight refresh
    private func refreshAppointmentsAndStats() async {
        guard !Task.isCancelled && isViewActive else { return }
        
        do {
            guard let doctorId = UUID(uuidString: currentUserId) else { return }
            
            // Only fetch appointments and stats
            async let appointmentsTask = supabase.fetchDoctorAppointments(doctorId: doctorId)
            async let statsTask = supabase.fetchDoctorStats(doctorId: doctorId)
            
            let (fetchedAppointments, stats) = try await (appointmentsTask, statsTask)
            
            await MainActor.run {
                // Update appointments and stats
                appointments = fetchedAppointments
                print("\n\nFetched Appointments: \n\n\(fetchedAppointments)\n\n")
                completedAppointments = stats.completedAppointments
                activePatients = stats.activePatients
            }
        } catch {
            print("Error refreshing appointments: \(error)")
        }
    }
}

#Preview {
    DoctorDashBoard()
}
