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
    @State private var refreshTimer: Timer?
    @State private var isViewActive = true
    @State private var loadDataTask: Task<Void, Never>?
    
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
                        startLoadingData()
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
                            startLoadingData()
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
    }
    
    private func startLoadingData() {
        cancelLoadingTask()
        loadDataTask = Task {
            await loadAppointments()
            
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
    
    private func loadAppointments() async {
        guard !Task.isCancelled && isViewActive else { return }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            guard let doctorId = UUID(uuidString: currentUserId) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid doctor ID"])
            }
            
            guard !Task.isCancelled else { return }
            let fetchedAppointments = try await supabase.fetchDoctorAppointments(doctorId: doctorId)
            
            guard !Task.isCancelled && isViewActive else { return }
            
            // Update appointments on main thread
            await MainActor.run {
                appointments = fetchedAppointments
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
                print("Error loading appointments:", error)
            }
        }
        
        guard !Task.isCancelled && isViewActive else { return }
        await MainActor.run {
            isLoading = false
        }
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
    
    func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
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
