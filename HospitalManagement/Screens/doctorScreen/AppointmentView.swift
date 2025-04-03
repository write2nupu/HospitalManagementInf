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
    @State private var showCancelledAlert = false
    
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
                    .padding(.top)
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
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        VStack(spacing: 2) {
                            if filteredAppointments.isEmpty {
                                Text("No appointments on this date.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(filteredAppointments) { appointment in
                                    upcomingAppointmentCard(appointment: appointment)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 3)
                    }
                }
            }
            .background(AppConfig.backgroundColor)
            .navigationTitle("Appointments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Profile button tapped")
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                    }
                }
            }
            .sheet(item: $selectedAppointment) { appointment in
                if appointment.status != .cancelled {
                    AppointmentDetailView(
                        appointment: appointment,
                        onStatusUpdate: { newStatus in
                            if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                                appointments[index].status = newStatus
                            }
                            startLoadingData()
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
        }
    }
    
    private func startLoadingData() {
        cancelLoadingTask()
        loadDataTask = Task {
            await loadAppointments()
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
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
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
            
            await MainActor.run {
                appointments = fetchedAppointments
            }
            
            var updatedNames: [UUID: String] = [:]
            for appointment in fetchedAppointments {
                guard !Task.isCancelled else { return }
                if patientNames[appointment.patientId] == nil {
                    do {
                        let patient = try await supabase.fetchPatientById(patientId: appointment.patientId)
                        updatedNames[appointment.patientId] = patient?.fullname
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
    
    func upcomingAppointmentCard(appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
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
