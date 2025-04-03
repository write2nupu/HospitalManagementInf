import SwiftUI

// First, make Appointment conform to Equatable
extension Appointment: Equatable {
    static func == (lhs: Appointment, rhs: Appointment) -> Bool {
        return lhs.id == rhs.id
    }
}

struct AppointmentListView: View {
    @State private var appointments: [Appointment] = []
    @State private var doctorNames: [UUID: String] = [:]
    @State private var isLoading = true
    @State private var showCancelConfirmation = false
    @State private var appointmentToCancel: Appointment?
    @State private var showRescheduleSheet = false
    @State private var appointmentToReschedule: Appointment?
    @StateObject private var supabaseController = SupabaseController()
    @State private var selectedSegment = 0 // 0 for upcoming, 1 for past
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented control in a separate container
            VStack {
                Picker("Appointment Type", selection: $selectedSegment) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            
            if isLoading {
                ProgressView("Loading appointments...")
                    .frame(maxHeight: .infinity)
            } else if appointments.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAppointments) { appointment in
                            AppointmentCard(
                                appointment: appointment,
                                doctorName: doctorNames[appointment.doctorId] ?? "Unknown Doctor",
                                onCancel: { appointmentToCancel = appointment },
                                onReschedule: { appointmentToReschedule = appointment },
                                isPast: selectedSegment == 1
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Appointments")
        .onAppear {
            Task {
                await fetchAppointments()
            }
        }
        .alert(isPresented: $showCancelConfirmation) {
            Alert(
                title: Text("Cancel Appointment"),
                message: Text("Are you sure you want to cancel this appointment?"),
                primaryButton: .destructive(Text("Yes, Cancel")) {
                    if let appointment = appointmentToCancel {
                        cancelAppointment(appointment)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showRescheduleSheet) {
            if let appointment = appointmentToReschedule {
                RescheduleView(
                    appointment: appointment,
                    onComplete: { newDate, newTime in
                        rescheduleAppointment(appointment, to: newDate, at: newTime)
                    }
                )
            }
        }
        .onChange(of: appointmentToCancel) { oldValue, newValue in
            showCancelConfirmation = newValue != nil
        }
        .onChange(of: appointmentToReschedule) { oldValue, newValue in
            showRescheduleSheet = newValue != nil
        }
    }
    
    // Computed property to filter appointments based on selected segment
    private var filteredAppointments: [Appointment] {
        let now = Date()
        let calendar = Calendar.current
        
        if selectedSegment == 0 {
            // Upcoming appointments (in the future)
            return appointments
                .filter { appointment in
                    let isInFuture = appointment.date > now
                    let isNotCancelled = appointment.status != .cancelled
                    let isCompleted = appointment.status != .completed
                    return isInFuture && isNotCancelled && isCompleted
                }
                .sorted { $0.date < $1.date }
        } else {
            // Past appointments (already happened)
            return appointments
                .filter { appointment in
                    let isInPast = appointment.date <= now
                    return isInPast || appointment.status == .cancelled
                }
                .sorted { $0.date > $1.date }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text(selectedSegment == 0 ? "No Upcoming Appointments" : "No Past Appointments")
                    .font(.title2)
                    .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text(selectedSegment == 0 ? 
                "You don't have any upcoming appointments scheduled. Book a new appointment to get started." :
                "You don't have any past appointment history.")
                .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private func fetchAppointments() async {
        isLoading = true
        
        do {
            guard let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
                  let patientId = UUID(uuidString: patientIdString) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Patient ID not found"])
            }
            
            // Fetch appointments specifically for this patient
            let fetchedAppointments = try await supabaseController.fetchAppointmentsForPatient(patientId: patientId)
            
            // Fetch doctor names for the appointments
            var doctorNamesDict: [UUID: String] = [:]
            for appointment in fetchedAppointments {
                if doctorNamesDict[appointment.doctorId] == nil {
                    if let doctor = try await supabaseController.fetchDoctorById(doctorId: appointment.doctorId) {
                        doctorNamesDict[appointment.doctorId] = doctor.full_name
                    }
                }
            }
            
            await MainActor.run {
                self.appointments = fetchedAppointments
                self.doctorNames = doctorNamesDict
                self.isLoading = false
            }
        } catch {
            print("Error fetching appointments: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func cancelAppointment(_ appointment: Appointment) {
        Task {
            do {
                try await supabaseController.cancelAppointment(appointmentId: appointment.id)
                await fetchAppointments() // Refresh the list
            } catch {
                print("Error canceling appointment: \(error)")
            }
        }
    }
    
    private func rescheduleAppointment(_ appointment: Appointment, to date: Date, at time: String) {
        Task {
            do {
                try await supabaseController.rescheduleAppointment(
                    appointmentId: appointment.id,
                    newDate: date,
                    newTime: time
                )
                await fetchAppointments() // Refresh the list
            } catch {
                print("Error rescheduling appointment: \(error)")
            }
        }
    }
}

// MARK: - Appointment Card
struct AppointmentCard: View {
    let appointment: Appointment
    let doctorName: String
    let onCancel: () -> Void
    let onReschedule: () -> Void
    let isPast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Doctor info row
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.mint.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.mint)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctorName)
                        .font(.headline)
                    
                    Text(appointment.type.rawValue)
                        .font(.subheadline)
                .foregroundColor(.secondary)
                }
                
                Spacer()
                
                statusBadge
            }
            
            Divider()
            
            // Updated date and time display
            HStack(spacing: 16) {
                dateView
                Spacer()
                timeView
            }
            
            // Only show action buttons for upcoming appointments that aren't cancelled
            if !isPast && appointment.status == .scheduled {
                Divider()
                actionButtons
                    }
                }
                .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var statusBadge: some View {
        Group {
            switch appointment.status {
            case .scheduled:
                if Calendar.current.date(byAdding: .hour, value: -1, to: Date())! > appointment.date {
                    statusLabel("Completed", color: .blue)
                } else {
                    statusLabel("Scheduled", color: .green)
                }
            case .cancelled:
                statusLabel("Cancelled", color: .red)
            case .completed:
                statusLabel("Completed", color: .blue)
            }
        }
    }
    
    private func statusLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
    
    private var dateView: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundColor(.mint)
            Text(formatDate(appointment.date))
                .font(.subheadline)
        }
    }
    
    private var timeView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .foregroundColor(.mint)
            Text(formatTime(appointment.date))
                .font(.subheadline)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onReschedule) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                    Text("Reschedule")
                }
                .font(.subheadline)
                .foregroundColor(.mint)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.mint, lineWidth: 1))
            }
            
            Spacer()
            
            Button(action: onCancel) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Cancel")
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy" // This will show date like "4 Apr 2025"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // 12-hour format with AM/PM
        return formatter.string(from: date)
    }
}

// Helper extension to split string at a specific character
private extension String {
    func split(at separator: Character) -> (String, String) {
        guard let index = firstIndex(of: separator) else { return (self, "") }
        return (String(prefix(upTo: index)), String(suffix(from: index).dropFirst()))
    }
}

// MARK: - Reschedule View
struct RescheduleView: View {
    let appointment: Appointment
    let onComplete: (Date, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var selectedTimeSlot: TimeSlot?
    @State private var showingAlert = false
    @State private var errorMessage = "Please select both a valid date and time slot."
    @StateObject private var supabaseController = SupabaseController()
    @State private var availableTimeSlots: [TimeSlot] = []
    @State private var isLoading = false
    @State private var selectedTime = Date()
    @State private var showTimePicker = false
    @State private var bookedTimeRanges: [String] = []
    
    init(appointment: Appointment, onComplete: @escaping (Date, String) -> Void) {
        self.appointment = appointment
        self.onComplete = onComplete
        
        // Initialize state with current appointment values
        _selectedDate = State(initialValue: appointment.date)
    }
    
    private var isValidSelection: Bool {
        selectedTimeSlot != nil && selectedDate >= Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("CURRENT APPOINTMENT")) {
                        HStack {
                            Text("Current Date:")
                            Spacer()
                            Text(formatDate(appointment.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Current Time:")
                            Spacer()
                            Text(formatTime(appointment.date))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("NEW DATE")) {
                        DatePicker(
                            "Select New Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .onChange(of: selectedDate) { _ in
                            selectedTimeSlot = nil
                            loadBookedTimeSlots()
                        }
                    }
                    
                    Section(header: Text("NEW TIME")) {
                        VStack {
                            Button(action: {
                                showTimePicker = true
                                loadBookedTimeSlots()
                            }) {
                                HStack {
                                    Text("Selected Time:")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if let slot = selectedTimeSlot {
                                        Text(slot.formattedTimeRange)
                                            .foregroundColor(.mint)
                                    } else {
                                        Text("Select a time")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            if showTimePicker {
                                if isLoading {
                                    ProgressView("Loading available times...")
                                        .padding()
                                } else {
                                    VStack {
                                        Text("Choose an available time")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 4)
                                        
                                        DatePicker("",
                                                 selection: $selectedTime,
                                                 displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.wheel)
                                            .labelsHidden()
                                            .onChange(of: selectedTime) { newTime in
                                                updateSelectedTimeSlot(time: newTime)
                                            }
                                        
                                        if !bookedTimeRanges.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Booked time slots:")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                ForEach(bookedTimeRanges, id: \.self) { range in
                                                    Text(range)
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                }
                                            }
                                            .padding(.top, 4)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        
                                        Button("Confirm Time") {
                                            showTimePicker = false
                                        }
                                        .foregroundColor(.mint)
                                        .padding(.top)
                                    }
                                    .padding(.vertical)
                                }
                            }
                            
                            if !TimeSlot.isValidTime(selectedTime) {
                                Text("Please select a time between 9 AM - 1 PM or 2 PM - 7 PM")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    Button("Confirm Changes") {
                        if !isValidSelection {
                            errorMessage = "Please select both a valid date and time slot."
                            showingAlert = true
                            return
                        }
                        
                        guard let timeSlot = selectedTimeSlot else {
                            errorMessage = "Please select a time slot."
                            showingAlert = true
                            return
                        }
                        
                        // Format the time slot as a string for the onComplete callback
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm" // Keep 24-hour format for database storage
                        let timeSlotString = formatter.string(from: timeSlot.startTime)
                        
                        onComplete(selectedDate, timeSlotString)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidSelection ? Color.mint : Color.gray.opacity(0.2))
                    .foregroundColor(isValidSelection ? .white : .gray)
                    .cornerRadius(10)
                    .disabled(!isValidSelection)
                }
                .padding()
            }
            .navigationTitle("Reschedule Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Rescheduling Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadBookedTimeSlots()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // 12-hour format with AM/PM
        return formatter.string(from: date)
    }
    
    private func loadBookedTimeSlots() {
        isLoading = true
        bookedTimeRanges = []
        
        Task {
            do {
                let allSlots = TimeSlot.generateTimeSlots(for: selectedDate)
                let availableSlots = try await supabaseController.getAvailableTimeSlots(
                    doctorId: appointment.doctorId,
                    date: selectedDate
                )
                
                // Find booked slots (all slots minus available slots)
                let bookedSlots = allSlots.filter { slot in
                    !availableSlots.contains { availableSlot in
                        availableSlot.startTime == slot.startTime && availableSlot.endTime == slot.endTime
                    }
                }
                
                // Format booked slots for display
                let formatter = DateFormatter()
                
                let bookedRanges = bookedSlots.map { slot in
                    "\(formatter.string(from: slot.startTime)) - \(formatter.string(from: slot.endTime))"
                }
                
                await MainActor.run {
                    bookedTimeRanges = bookedRanges
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error loading booked time slots"
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func updateSelectedTimeSlot(time: Date) {
        if TimeSlot.isValidTime(time) {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            if let slotStart = calendar.date(from: components) {
                let slotEnd = calendar.date(byAdding: .minute, value: 20, to: slotStart)!
                let newSlot = TimeSlot(startTime: slotStart, endTime: slotEnd)
                
                Task {
                    do {
                        let isAvailable = try await supabaseController.checkTimeSlotAvailability(
                            doctorId: appointment.doctorId,
                            timeSlot: newSlot
                        )
                        
                        await MainActor.run {
                            if isAvailable {
                                selectedTimeSlot = newSlot
                                errorMessage = ""
                            } else {
                                selectedTimeSlot = nil
                                errorMessage = "This time slot is already booked. Please select a different time."
                            }
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = "Error checking time slot availability"
                            showingAlert = true
                            selectedTimeSlot = nil
                        }
                    }
                }
            }
        } else {
            selectedTimeSlot = nil
        }
    }
} 
