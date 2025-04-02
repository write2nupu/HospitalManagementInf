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
                .shadow(color: AppConfig.shadowColor, radius: 4, x: 0, y: 2)
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
