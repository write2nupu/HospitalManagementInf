import SwiftUI

struct AppointmentListView: View {
    @Binding var savedAppointments: [[String: Any]]
    @State private var selectedAppointmentIndex: Int?
    @State private var isRescheduling = false
    @State private var showCancelConfirmation = false
    @State private var appointmentToCancel: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header title for "UPCOMING APPOINTMENTS"
            Text("UPCOMING APPOINTMENTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
            
            ScrollView {
                LazyVStack(spacing: 15, pinnedViews: []) {
                    ForEach(savedAppointments.indices, id: \.self) { index in
                        AppointmentCard(
                            appointment: savedAppointments[index],
                            isReschedulable: isAppointmentReschedulable(savedAppointments[index]),
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
        .sheet(item: Binding(
            get: { selectedAppointmentIndex.map { AppointmentWrapper(id: $0, appointment: savedAppointments[$0]) } },
            set: { wrapper in selectedAppointmentIndex = wrapper?.id }
        )) { wrapper in
            RescheduleView(
                appointment: savedAppointments[wrapper.id],
                onComplete: { newDate, newTimeSlot in
                    rescheduleAppointment(at: wrapper.id, newDate: newDate, newTimeSlot: newTimeSlot)
                }
            )
        }
        .alert("Cancel Appointment", isPresented: $showCancelConfirmation) {
            Button("Cancel", role: .cancel) {
                // Do nothing, just dismiss the alert
            }
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
        guard let appointmentDate = appointment["date"] as? Date else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let appointmentDay = calendar.startOfDay(for: appointmentDate)
        return appointmentDay >= today
    }
    
    private func deleteAppointment(at offsets: IndexSet) {
        savedAppointments.remove(atOffsets: offsets)
        UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
    }
    
    private func rescheduleAppointment(at index: Int, newDate: Date, newTimeSlot: String) {
        // Make a copy of the appointment
        var updatedAppointment = savedAppointments[index]
        
        // Store original date and time if this is first reschedule
        if updatedAppointment["originalDate"] == nil {
            updatedAppointment["originalDate"] = updatedAppointment["date"]
            updatedAppointment["originalTimeSlot"] = updatedAppointment["timeSlot"]
        }
        
        // Update date and time
        updatedAppointment["date"] = newDate
        updatedAppointment["timeSlot"] = newTimeSlot
        updatedAppointment["isRescheduled"] = true
        updatedAppointment["lastRescheduledAt"] = Date() // When the reschedule happened
        updatedAppointment["timestamp"] = Date() // Add timestamp for latest appointment tracking
        
        // Replace in array
        savedAppointments[index] = updatedAppointment
        
        // Save to UserDefaults
        UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
        
        // Reset state
        selectedAppointmentIndex = nil
    }
    
    private func formatDate(_ dateObj: Any?) -> String {
        guard let date = dateObj as? Date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Wrapper to make Dictionary Identifiable for sheet presentation
struct AppointmentWrapper: Identifiable {
    let id: Int
    let appointment: [String: Any]
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
                Image(systemName: appointment["appointmentType"] as? String == "Emergency" ? "cross.case.fill" : "calendar.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(appointment["appointmentType"] as? String == "Emergency" ? .red : .mint)
                
                Text(appointment["doctorName"] as? String ?? "")
                    .font(.headline)
                
                Spacer()
                
                Text(appointment["appointmentType"] as? String ?? "")
                    .font(.subheadline)
                    .foregroundColor(appointment["appointmentType"] as? String == "Emergency" ? .red : .mint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(appointment["appointmentType"] as? String == "Emergency" ? 
                                Color.red.opacity(0.1) : Color.mint.opacity(0.1))
                    )
            }
            
            Divider()
            
            // Appointment Details
            VStack(alignment: .leading, spacing: 8) {
                // If appointment has been rescheduled, show a badge
                if let isRescheduled = appointment["isRescheduled"] as? Bool, isRescheduled {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                        Text("Rescheduled")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // Current Appointment details
                HStack(spacing: 20) {
                    // Date
                    Label {
                        Text(formatDate(appointment["date"]))
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                    }
                    
                    // Time
                    Label {
                        Text(appointment["timeSlot"] as? String ?? "")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                    }
                }
                
                // Show original date/time if this is a rescheduled appointment
                if let isRescheduled = appointment["isRescheduled"] as? Bool, 
                   isRescheduled,
                   let originalDate = appointment["originalDate"] as? Date,
                   let originalTimeSlot = appointment["originalTimeSlot"] as? String {
                    
                    Text("Originally scheduled for:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    HStack(spacing: 20) {
                        // Original Date
                        Label {
                            Text(formatDate(originalDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.gray)
                        }
                        
                        // Original Time
                        Label {
                            Text(originalTimeSlot)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.gray)
                        }
                    }
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
    
    private func formatDate(_ dateObj: Any?) -> String {
        guard let date = dateObj as? Date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
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
        let initialDate = appointment["date"] as? Date ?? Date()
        let initialTimeSlot = appointment["timeSlot"] as? String ?? ""
        
        _selectedDate = State(initialValue: initialDate)
        _selectedTimeSlot = State(initialValue: initialTimeSlot)
    }
    
    private var isValidSelection: Bool {
        !selectedTimeSlot.isEmpty && selectedDate >= Calendar.current.startOfDay(for: Date())
    }
    
    // Check if new date & time slot is already booked by another appointment
    private func isTimeSlotAlreadyBooked(date: Date, timeSlot: String) -> Bool {
        // Get all saved appointments
        let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        let currentAppointmentId = appointment["id"] as? String
        
        // Create calendar for date comparison
        let calendar = Calendar.current
        
        // Check if any other appointment matches the date and time slot
        return savedAppointments.contains { existingAppointment in
            // Skip the current appointment being rescheduled
            if let appointmentId = existingAppointment["id"] as? String,
               appointmentId == currentAppointmentId {
                return false
            }
            
            guard let appointmentDate = existingAppointment["date"] as? Date,
                  let appointmentTimeSlot = existingAppointment["timeSlot"] as? String else {
                return false
            }
            
            // Compare dates (same day) and time slot
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
                            Text(formatDate(appointment["date"]))
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
                        
                        // Check if this time slot is already booked
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
    
    private func formatDate(_ dateObj: Any?) -> String {
        guard let date = dateObj as? Date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 