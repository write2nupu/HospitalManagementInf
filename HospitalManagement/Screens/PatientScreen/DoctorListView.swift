import SwiftUI

struct DoctorListView: View {
    let doctors: [Doctor]
    @State private var selectedDoctor: Doctor?
    @State private var showAppointmentBookingModal = false
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: String?
    @StateObject private var supabaseController = SupabaseController()
    @State private var departmentDetails: [UUID: Department] = [:]
    @State private var isBookingAppointment = false
    @State private var bookingError: Error?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAppointmentType: AppointmentBookingView.AppointmentType?
    
    // Time slots for demonstration
    private let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM", 
        "02:00 PM", "03:00 PM", "04:00 PM"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(doctors) { doctor in
                    Button(action: {
                        selectedDoctor = doctor
                        showAppointmentBookingModal = true
                    }) {
                        doctorCard(doctor: doctor)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select Doctor")
        .background(Color.mint.opacity(0.05))
        .task {
            // Fetch department details for each doctor
            for doctor in doctors {
                if let departmentId = doctor.department_id {
                    if let department = await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
                        departmentDetails[departmentId] = department
                    }
                }
            }
        }
        .sheet(isPresented: $showAppointmentBookingModal) {
            if let doctor = selectedDoctor {
                AppointmentBookingView(
                    doctor: doctor,
                    selectedDate: $selectedDate,
                    selectedTimeSlot: $selectedTimeSlot,
                    isBookingAppointment: $isBookingAppointment,
                    bookingError: $bookingError,
                    selectedAppointmentType: $selectedAppointmentType,
                    onBookAppointment: bookAppointment
                )
            }
        }
        .alert(isPresented: Binding.constant(bookingError != nil)) {
            Alert(
                title: Text("Booking Error"),
                message: Text(bookingError?.localizedDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    bookingError = nil
                }
            )
        }
    }
    
    private func bookAppointment() {
        guard let doctor = selectedDoctor,
              let appointmentType = selectedAppointmentType else {
            return
        }
        
        // Validate time slot based on appointment type
        if appointmentType == .consultation {
            guard let timeSlot = selectedTimeSlot else { return }
            // Additional validation for consultation
        } else if appointmentType == .emergency {
            // For emergency, ensure time slot is "NOW"
            guard selectedTimeSlot == "NOW" else { return }
        }
        
        isBookingAppointment = true
        
        Task {
            do {
                // TODO: Replace with actual appointment booking method from Supabase controller
                // Simulating an async booking process
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                
                // Prepare appointment details
                let appointmentDetails: [String: Any] = [
                    "doctorName": doctor.full_name,
                    "appointmentType": appointmentType.rawValue,
                    "date": selectedDate,
                    "timeSlot": selectedTimeSlot ?? "NOW",
                    "timestamp": Date()
                ]
                
                // Save appointment details to UserDefaults
                var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
                savedAppointments.append(appointmentDetails)
                UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
                
                // Reset and dismiss
                DispatchQueue.main.async {
                    isBookingAppointment = false
                    showAppointmentBookingModal = false
                    selectedTimeSlot = nil
                    selectedAppointmentType = nil
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isBookingAppointment = false
                    bookingError = error
                }
            }
        }
    }
    
    // MARK: - Doctor Card UI
    private func doctorCard(doctor: Doctor) -> some View {
        HStack(spacing: 15) {
            Image(systemName: "person.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.mint)
                .background(Color.mint.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(doctor.full_name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let departmentId = doctor.department_id,
                   let department = departmentDetails[departmentId] {
                    Text(department.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("₹\(Int(department.fees))")
                        .font(.body)
                        .foregroundColor(.mint)
                } else {
                    Text("Department not assigned")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Appointment Booking Modal View
struct AppointmentBookingView: View {
    let doctor: Doctor
    @Binding var selectedDate: Date
    @Binding var selectedTimeSlot: String?
    @Binding var isBookingAppointment: Bool
    @Binding var bookingError: Error?
    @Binding var selectedAppointmentType: AppointmentType?
    var onBookAppointment: () -> Void
    
    // Appointment Types
    enum AppointmentType: String, CaseIterable {
        case consultation = "Consultation"
        case emergency = "Emergency"
    }
    
    // Time slots for demonstration
    private let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM", 
        "02:00 PM", "03:00 PM", "04:00 PM"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Doctor Information Section
                Section(header: Text("Doctor Details")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.mint)
                        VStack(alignment: .leading) {
                            Text(doctor.full_name)
                                .font(.headline)
                            Text("Consultation Fee: ₹20")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Appointment Type Section
                Section(header: Text("Appointment Type")) {
                    VStack(spacing: 15) {
                        ForEach(AppointmentType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedAppointmentType = type
                                // Reset date and time slot when changing type
                                if type == .emergency {
                                    selectedDate = Date()
                                    selectedTimeSlot = "NOW"
                                } else {
                                    selectedTimeSlot = nil
                                }
                            }) {
                                HStack {
                                    // Different icons for each appointment type
                                    Image(systemName: type == .emergency ? "cross.case.fill" : "stethoscope")
                                        .foregroundColor(.white)
                                        .frame(width: 30, height: 30)
                                        .background(
                                            Circle()
                                                .fill(iconBackgroundColor(type))
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text(type.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text(type == .emergency ? 
                                             "Immediate medical attention required" : 
                                             "Regular consultation with the doctor")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Selection indicator
                                    if selectedAppointmentType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(type == .emergency ? .red : .mint)
                                    }
                                }
                                .padding()
                                .background(backgroundColorForAppointmentType(type))
                                .overlay(
                                    overlayForAppointmentType(type)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                // Conditional Date and Time Selection
                if selectedAppointmentType == .consultation {
                    // Date Selection Section
                    Section(header: Text("Select Date")) {
                        DatePicker("Appointment Date", 
                                   selection: $selectedDate, 
                                   in: Date()..., 
                                   displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                    
                    // Time Slot Selection Section
                    Section(header: Text("Select Time Slot")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(timeSlots, id: \.self) { slot in
                                    Button(action: {
                                        selectedTimeSlot = (selectedTimeSlot == slot) ? nil : slot
                                    }) {
                                        Text(slot)
                                            .padding(10)
                                            .background(
                                                selectedTimeSlot == slot ? 
                                                Color.mint : Color.gray.opacity(0.2)
                                            )
                                            .foregroundColor(
                                                selectedTimeSlot == slot ? 
                                                .white : .primary
                                            )
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedTimeSlot == slot ? Color.mint : Color.gray, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                    }
                } else if selectedAppointmentType == .emergency {
                    // Emergency Section
                    Section(header: Text("Emergency Appointment")) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Immediate Assistance")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        Text("You will be connected to the nearest available doctor immediately.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarItems(
                trailing: Button(isBookingAppointment ? "Booking..." : "Book") {
                    onBookAppointment()
                }
                .disabled(
                    (selectedAppointmentType == .consultation && 
                     (selectedTimeSlot == nil || selectedDate == nil)) ||
                    (selectedAppointmentType == .emergency && selectedTimeSlot != "NOW") ||
                    isBookingAppointment
                )
            )
        }
    }
    
    private func backgroundColorForAppointmentType(_ type: AppointmentType) -> Color {
        guard selectedAppointmentType == type else {
            return Color.gray.opacity(0.1)
        }
        
        switch type {
        case .consultation:
            return Color.mint.opacity(0.1)
        case .emergency:
            return Color.red.opacity(0.1)
        }
    }
    
    private func overlayForAppointmentType(_ type: AppointmentType) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(selectedAppointmentType == type ? 
                    (type == .emergency ? Color.red : Color.mint) : Color.gray.opacity(0.3), 
                    lineWidth: 2)
    }
    
    private func iconBackgroundColor(_ type: AppointmentType) -> Color {
        return type == .emergency ? Color.red : Color.mint
    }
}
