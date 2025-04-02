import SwiftUI

struct AppointmentListView: View {
    @State private var appointments: [[String: Any]] = []
    @State private var selectedAppointmentIndex: Int?
    @State private var showCancelConfirmation = false
    @State private var appointmentToCancel: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            if appointments.isEmpty {
                emptyStateView
            } else {
                appointmentListView
            }
        }
        .onAppear {
            loadAppointments()
            
            // Add observer for refresh
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshAppointments"),
                object: nil,
                queue: .main
            ) { _ in
                loadAppointments()
            }
            
            // Add observer for new appointments
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("AppointmentBooked"),
                object: nil,
                queue: .main
            ) { notification in
                handleNewAppointment(notification)
            }
        }
        .sheet(item: Binding(
            get: { selectedAppointmentIndex.map { AppointmentWrapper(id: $0, appointment: appointments[$0]) } },
            set: { wrapper in selectedAppointmentIndex = wrapper?.id }
        )) { wrapper in
            RescheduleView(
                appointment: appointments[wrapper.id],
                onComplete: { newDate, newTimeSlot in
                    rescheduleAppointment(at: wrapper.id, newDate: newDate, newTimeSlot: newTimeSlot)
                }
            )
        }
    }
    
    private func loadAppointments() {
        appointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        print("📅 Loaded appointments: \(appointments)")
    }
    
    private func handleNewAppointment(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let appointmentDict = userInfo["appointment"] as? [String: Any] else {
            print("❌ Failed to get appointment data from notification")
            return
        }
        
        print("📝 Received new appointment: \(appointmentDict)")
        
        // Get existing appointments
        var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        
        // Add new appointment
        savedAppointments.append(appointmentDict)
        
        // Save back to UserDefaults
        UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
        
        // Update local state
        appointments = savedAppointments
        
        print("✅ Saved appointments: \(savedAppointments)")
    }
    
    private func rescheduleAppointment(at index: Int, newDate: Date, newTimeSlot: String) {
        var updatedAppointment = appointments[index]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        // Store original date and time if this is first reschedule
        if updatedAppointment["originalDate"] == nil {
            updatedAppointment["originalDate"] = updatedAppointment["date"]
            updatedAppointment["originalTimeSlot"] = updatedAppointment["timeSlot"]
        }
        
        // Update date and time
        updatedAppointment["date"] = dateFormatter.string(from: newDate)
        updatedAppointment["timeSlot"] = newTimeSlot
        updatedAppointment["isRescheduled"] = true
        updatedAppointment["lastRescheduledAt"] = dateFormatter.string(from: Date())
        
        // Replace in array
        appointments[index] = updatedAppointment
        
        // Save to UserDefaults
        UserDefaults.standard.set(appointments, forKey: "savedAppointments")
        
        // Reset state
        selectedAppointmentIndex = nil
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Appointments")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Book your first appointment to see it here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: DepartmentListView()) {
                Text("Book Appointment")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.mint)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var appointmentListView: some View {
        VStack(spacing: 0) {
            Text("UPCOMING APPOINTMENTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
            
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(appointments.indices, id: \.self) { index in
                        AppointmentCard(
                            appointment: appointments[index],
                            isReschedulable: isAppointmentReschedulable(appointments[index]),
                            onReschedule: {
                                selectedAppointmentIndex = index
                            },
                            onCancel: {
                                appointmentToCancel = index
                                showCancelConfirmation = true
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .alert("Cancel Appointment", isPresented: $showCancelConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                if let index = appointmentToCancel {
                    deleteAppointment(at: IndexSet(integer: index))
                    appointmentToCancel = nil
                }
            }
        } message: {
            Text("Are you sure you want to cancel this appointment?")
        }
    }
    
    private func isAppointmentReschedulable(_ appointment: [String: Any]) -> Bool {
        guard let dateString = appointment["date"] as? String else { return false }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let appointmentDate = dateFormatter.date(from: dateString) else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let appointmentDay = calendar.startOfDay(for: appointmentDate)
        return appointmentDay >= today
    }
    
    private func deleteAppointment(at offsets: IndexSet) {
        appointments.remove(atOffsets: offsets)
        UserDefaults.standard.set(appointments, forKey: "savedAppointments")
    }
}

// Wrapper to make Dictionary Identifiable for sheet presentation
struct AppointmentWrapper: Identifiable {
    let id: Int
    let appointment: [String: Any]
}

// MARK: - Reschedule View
struct RescheduleView: View {
    let appointment: [String: Any]
    let onComplete: (Date, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var selectedTimeSlot: String
    @State private var showingAlert = false
    @State private var errorMessage = "Please select both a valid date and time slot."
    
    private let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM",
        "02:00 PM", "03:00 PM", "04:00 PM"
    ]
    
    init(appointment: [String: Any], onComplete: @escaping (Date, String) -> Void) {
        self.appointment = appointment
        self.onComplete = onComplete
        
        // Initialize state with current appointment values
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let initialDate = dateFormatter.date(from: appointment["date"] as? String ?? "") ?? Date()
        let initialTimeSlot = appointment["timeSlot"] as? String ?? ""
        
        _selectedDate = State(initialValue: initialDate)
        _selectedTimeSlot = State(initialValue: initialTimeSlot)
    }
    
    private var isValidSelection: Bool {
        !selectedTimeSlot.isEmpty && selectedDate >= Calendar.current.startOfDay(for: Date())
    }
    
    private func isTimeSlotAlreadyBooked(date: Date, timeSlot: String) -> Bool {
        let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        let currentAppointmentId = appointment["id"] as? String
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        return savedAppointments.contains { existingAppointment in
            if let appointmentId = existingAppointment["id"] as? String,
               appointmentId == currentAppointmentId {
                return false
            }
            
            guard let appointmentDateStr = existingAppointment["date"] as? String,
                  let appointmentDate = dateFormatter.date(from: appointmentDateStr),
                  let appointmentTimeSlot = existingAppointment["timeSlot"] as? String else {
                return false
            }
            
            let sameDay = calendar.isDate(appointmentDate, inSameDayAs: date)
            let sameTimeSlot = appointmentTimeSlot == timeSlot
            
            return sameDay && sameTimeSlot
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("CURRENT APPOINTMENT")) {
                        HStack {
                            Text("Current Date:")
                            Spacer()
                            Text(formatDate(appointment["date"] as? String))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Current Time:")
                            Spacer()
                            Text(appointment["timeSlot"] as? String ?? "")
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
                    }
                    
                    Section(header: Text("NEW TIME")) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Button(action: {
                                selectedTimeSlot = slot
                            }) {
                                HStack {
                                    Text(slot)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedTimeSlot == slot {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
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
                        
                        if isTimeSlotAlreadyBooked(date: selectedDate, timeSlot: selectedTimeSlot) {
                            errorMessage = "You already have another appointment at this date and time."
                            showingAlert = true
                            return
                        }
                        
                        onComplete(selectedDate, selectedTimeSlot)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidSelection ? Color.blue : Color.gray.opacity(0.2))
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
        }
    }
    
    private func formatDate(_ dateString: String?) -> String {
        guard let dateStr = dateString else { return "N/A" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        guard let date = inputFormatter.date(from: dateStr) else { return "N/A" }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        return outputFormatter.string(from: date)
    }
}

// MARK: - Appointment Card
struct AppointmentCard: View {
    let appointment: [String: Any]
    let isReschedulable: Bool
    let onReschedule: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: (appointment["type"] as? String == "Emergency") ? "cross.case.fill" : "calendar.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(appointment["type"] as? String == "Emergency" ? .red : .mint)
                
                Text(appointment["doctorName"] as? String ?? "")
                    .font(.headline)
                
                Spacer()
                
                Text(appointment["type"] as? String ?? "")
                    .font(.subheadline)
                    .foregroundColor(appointment["type"] as? String == "Emergency" ? .red : .mint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(appointment["type"] as? String == "Emergency" ? 
                                Color.red.opacity(0.1) : Color.mint.opacity(0.1))
                    )
            }
            
            Divider()
            
            // Appointment Details
            VStack(alignment: .leading, spacing: 8) {
                // Date and Time
                HStack(spacing: 20) {
                    Label {
                        Text(formatDate(appointment["date"] as? String))
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                    }
                    
                    Label {
                        Text(appointment["timeSlot"] as? String ?? "")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                    }
                }
                
                // Doctor and Department
                if let doctorName = appointment["doctorName"] as? String,
                   let departmentName = appointment["departmentName"] as? String {
                    Text("\(doctorName) • \(departmentName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Hospital
                if let hospitalName = appointment["hospitalName"] as? String {
                    Text(hospitalName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 15) {
                if isReschedulable {
                    Button(action: onReschedule) {
                        Label("Reschedule", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                            .foregroundColor(.mint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.mint.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Button(action: onCancel) {
                    Label("Cancel", systemImage: "xmark")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ dateString: String?) -> String {
        guard let dateStr = dateString else { return "N/A" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        guard let date = inputFormatter.date(from: dateStr) else { return "N/A" }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        return outputFormatter.string(from: date)
    }
} 