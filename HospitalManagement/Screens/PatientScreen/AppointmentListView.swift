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
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar first
            searchBar
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color(.systemBackground))
            
            // Segmented control below search
            VStack {
                Picker("Appointment Type", selection: $selectedSegment) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            
            if isLoading {
                ProgressView("Loading appointments...")
                    .frame(maxHeight: .infinity)
            } else if filteredAppointments.isEmpty {
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
        
        // First filter by segment (upcoming/past)
        var filtered = appointments.filter { appointment in
            if selectedSegment == 0 {
                // Upcoming appointments
                let isInFuture = appointment.date > now
                let isNotCancelled = appointment.status != .cancelled
                let isCompleted = appointment.status != .completed
                return isInFuture && isNotCancelled && isCompleted
            } else {
                // Past appointments
                let isInPast = appointment.date <= now
                return isInPast || appointment.status == .cancelled
            }
        }
        
        // Then apply search if text is not empty
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filtered = filtered.filter { appointment in
                let doctorName = doctorNames[appointment.doctorId]?.lowercased() ?? ""
                let dateString = appointment.date.formatted(.dateTime.day().month().year())
                let statusString = appointment.status.rawValue.lowercased()
                
                return doctorName.contains(lowercasedSearch) ||
                       dateString.lowercased().contains(lowercasedSearch) ||
                       statusString.contains(lowercasedSearch)
            }
        }
        
        // Sort by date
        return filtered.sorted { selectedSegment == 0 ? $0.date < $1.date : $0.date > $1.date }
    }
    
    // Updated searchBar view with better styling
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search by doctor, status, or date...", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            if !searchText.isEmpty {
                Text("No matching appointments")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Text("Try adjusting your search")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
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
            doctorSection
            
            Divider()
            
            // Updated date and time display
            HStack(spacing: 16) {
                if appointment.type == .Emergency {
                    Text("Emergency Request")
                        .foregroundColor(.red)
                        .font(.subheadline)
                } else {
                    dateView
            Spacer()
                    timeView
                }
            }
            
            // Only show action buttons for upcoming regular appointments that aren't cancelled
            if !isPast && appointment.status == .scheduled && appointment.type != .Emergency {
                Divider()
                actionButtons
            }
        }
        .padding()
        .background(Color(AppConfig.cardColor))
        .cornerRadius(16)
        .shadow(color: AppConfig.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    private var doctorSection: some View {
        HStack(spacing: 12) {
//            Circle()
//                .fill(Color.mint.opacity(0.2))
//                .frame(width: 40, height: 40)
//                .overlay(
//                    Image(systemName: appointment.type == .Emergency ? "cross.case.fill" : "person.fill")
//                        .foregroundColor(.mint)
//                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.type == .Emergency ? "Emergency Appointment" : doctorName)
                    .font(.headline)
                
                Text(appointment.type.rawValue)
                    .font(.subheadline)
                .foregroundColor(.secondary)
            }
        
            Spacer()
            
            statusBadge
        }
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
                .foregroundColor(AppConfig.buttonColor)
            Text(formatDate(appointment.date))
                .font(.subheadline)
        }
    }
    
    private var timeView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .foregroundColor(AppConfig.buttonColor)
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
                .foregroundColor(AppConfig.buttonColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(AppConfig.buttonColor, lineWidth: 1))
            }
            
            Spacer()
            
            Button(action: onCancel) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Cancel")
                }
                .font(.subheadline)
                .foregroundColor(AppConfig.redColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(AppConfig.redColor, lineWidth: 1))
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
                            in: Date()...Calendar.current.date(byAdding: .day, value: 28, to: Date())!,
                            displayedComponents: .date
                        )
                        .onChange(of: selectedDate) { oldValue, _ in
                            selectedTimeSlot = nil
                            loadBookedTimeSlots()
                        }
                    }
                    
                    Section(header: Text("NEW TIME")) {
                        VStack {
                            if isLoading {
                                ProgressView("Loading available times...")
                                    .padding()
                            } else {
                                // Time slots grid
                                Text("Choose an available time")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                let timeSlotStrings = availableTimeSlots.map { slot in
                                    let formatter = DateFormatter()
                                    formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!
                                    formatter.timeStyle = .short
                                    return formatter.string(from: slot.startTime)
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 10) {
                                    ForEach(timeSlotStrings, id: \.self) { timeString in
                                        Button(action: {
                                            selectTimeFromString(timeString)
                                        }) {
                                            Text(timeString)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .frame(maxWidth: .infinity)
                                                .background(isSelectedTimeString(timeString) ? AppConfig.buttonColor : Color.mint.opacity(0.1))
                                                .foregroundColor(isSelectedTimeString(timeString) ? .black : .primary)
                                                .cornerRadius(8)
                                        }
                                        .disabled(isTimeBooked(timeString))
                                        .buttonStyle(BorderlessButtonStyle()) // Prevents button behavior from affecting parent views
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                if selectedTimeSlot != nil {
                                    Text("Selected time: \(selectedTimeSlot!.formattedTimeRange)")
                                        .font(.subheadline)
                                        .foregroundColor(.mint)
                                        .padding(.top, 4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
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
                    .background(AppConfig.redColor)
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
                
                // Filter out slots that are in the past if selected date is today
                let currentDate = Date()
                let filteredAvailableSlots = availableSlots.filter { slot in
                    // If it's today, filter out past slots
                    if Calendar.current.isDateInToday(selectedDate) {
                        return slot.startTime > currentDate
                    }
                    // If it's a future date, include all slots
                    return true
                }
                
                // Find booked slots (all slots minus available slots)
                let bookedSlots = allSlots.filter { slot in
                    !filteredAvailableSlots.contains { availableSlot in
                        availableSlot.startTime == slot.startTime && availableSlot.endTime == slot.endTime
                    }
                }
                
                // Format booked slots for display
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!
                formatter.timeStyle = .short
                
                let bookedRanges = bookedSlots.map { slot in
                    formatter.string(from: slot.startTime)
                }
                
                await MainActor.run {
                    self.availableTimeSlots = filteredAvailableSlots
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
    
    private func isTimeBooked(_ timeString: String) -> Bool {
        // Check if the time is in the past
        if Calendar.current.isDateInToday(selectedDate) {
            let timeComponents = timeString.split(separator: ":")
            if timeComponents.count == 2,
               let hour = Int(timeComponents[0]),
               let minute = Int(timeComponents[1]) {
                
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                if let slotTime = Calendar.current.date(from: dateComponents) {
                    if slotTime < Date() {
                        return true  // Time is in the past, consider it booked
                    }
                }
            }
        }
        
        // Also check if it's in the booked ranges
        return bookedTimeRanges.contains(timeString)
    }
    
    private func isSelectedTimeString(_ timeString: String) -> Bool {
        guard let slot = selectedTimeSlot else { return false }
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        formatter.timeStyle = .short
        let selectedTimeString = formatter.string(from: slot.startTime)
        
        return selectedTimeString == timeString
    }
    
    private func selectTimeFromString(_ timeString: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        dateFormatter.timeStyle = .short
        
        let timeComponents = timeString.split(separator: ":")
        if timeComponents.count == 2,
           let hour = Int(timeComponents[0]),
           let minute = Int(timeComponents[1]) {
            
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            if let slotStart = Calendar.current.date(from: dateComponents) {
                // Check if the selected time is before current time
                if slotStart < Date() {
                    errorMessage = "Cannot select a time slot in the past. Please select a future time."
                    showingAlert = true
                    return
                }
                
                // Find the time slot that matches this string
                if let matchingSlot = availableTimeSlots.first(where: { slot in
                    let slotTimeString = dateFormatter.string(from: slot.startTime)
                    return slotTimeString == timeString
                }) {
                    selectedTimeSlot = matchingSlot
                }
            }
        }
    }
} 
