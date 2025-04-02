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
    @Environment(\.presentationMode) private var presentationMode
    @State private var shouldNavigateToDashboard = false
    @State private var selectedAppointmentType: AppointmentBookingView.AppointmentType?
    @State private var searchText = ""
    @StateObject private var coordinator = NavigationCoordinator.shared
    @Environment(\.rootNavigation) private var rootNavigation
    
    // Time slots for demonstration
    private let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM", 
        "02:00 PM", "03:00 PM", "04:00 PM"
    ]
    
    // Filtered doctors based on search
    private var filteredDoctors: [Doctor] {
        if searchText.isEmpty {
            return doctors
        } else {
            return doctors.filter { doctor in
                let name = doctor.full_name.lowercased()
                let search = searchText.lowercased()
                
                // Filter by name only since 'specialization' doesn't exist
                return name.contains(search)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                TextField("Search by doctor name", text: $searchText)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
            .padding(.top)
            
        ScrollView {
                if filteredDoctors.isEmpty {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)
                        
                        if searchText.isEmpty {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No doctors available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No doctors match '\(searchText)'")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button("Clear Search") {
                                searchText = ""
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.mint)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    // Results Counter
                    if !searchText.isEmpty {
                        HStack {
                            Text("Found \(filteredDoctors.count) doctor(s)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
            VStack(spacing: 15) {
                        ForEach(filteredDoctors) { doctor in
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
            }
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
        .onChange(of: coordinator.shouldDismissToRoot) { oldValue, shouldDismiss in
            print("🔄 DoctorListView: shouldDismissToRoot changed to \(shouldDismiss)")
            if shouldDismiss {
                print("👋 DoctorListView: Dismissing view")
                dismiss()
            }
        }
        .onAppear {
            print("👀 DoctorListView: View appeared")
        }
        .onDisappear {
            print("👋 DoctorListView: View disappeared")
        }
        .sheet(isPresented: $showAppointmentBookingModal) {
            if let doctor = selectedDoctor {
                AppointmentBookingView(
                    doctor: doctor,
                    selectedDate: $selectedDate,
                    selectedTimeSlot: $selectedTimeSlot,
                    isBookingAppointment: $isBookingAppointment,
                    bookingError: $bookingError,
                    onBookAppointment: bookAppointment,
                    selectedAppointmentType: $selectedAppointmentType
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
    
    // Book appointment function
    func bookAppointment() {
        guard let timeSlot = selectedTimeSlot else {
            // Cannot book without a time slot
            bookingError = NSError(domain: "AppointmentBooking", 
                                 code: 1, 
                                 userInfo: [NSLocalizedDescriptionKey: "Please select a time slot"])
            return
        }
        
        // Check if user already has an appointment at this date and time
        if isTimeSlotAlreadyBooked(date: selectedDate, timeSlot: timeSlot) {
            bookingError = NSError(domain: "AppointmentBooking", 
                                 code: 2, 
                                 userInfo: [NSLocalizedDescriptionKey: "You already have an appointment at this date and time"])
            return
        }
        
        // Start booking process
        isBookingAppointment = true
        bookingError = nil
        
        // Simulate booking process with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let doctor = self.selectedDoctor else { return }
            
            // Prepare appointment details
            let appointmentDetails: [String: Any] = [
                "id": UUID().uuidString,
                "doctorName": doctor.full_name,
                "doctorSpecialty": self.departmentDetails[doctor.department_id ?? UUID()]?.name ?? "Unknown Specialty",
                "date": self.selectedDate,
                "timeSlot": timeSlot,
                "appointmentType": self.selectedAppointmentType?.rawValue ?? "Consultation",
                "timestamp": Date() // Add timestamp for latest appointment tracking
            ]
            
            // Get existing appointments
            var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
            
            // Add new appointment
            savedAppointments.append(appointmentDetails)
            
            // Save to UserDefaults
            UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
            
            // Reset state
            self.isBookingAppointment = false
            self.showAppointmentBookingModal = false
            self.selectedTimeSlot = nil
            self.selectedAppointmentType = nil
            self.dismiss()
        }
    }
    
    // Check if user already has an appointment at this date and time
    private func isTimeSlotAlreadyBooked(date: Date, timeSlot: String) -> Bool {
        // Get existing appointments
        let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        
        // Create calendar for date comparison
        let calendar = Calendar.current
        
        // Check if any appointment matches the date and time slot
        return savedAppointments.contains { appointment in
            guard let appointmentDate = appointment["date"] as? Date,
                  let appointmentTimeSlot = appointment["timeSlot"] as? String else {
                return false
            }
            
            // Compare dates (same day) and time slot
            let sameDay = calendar.isDate(appointmentDate, inSameDayAs: date)
            let sameTimeSlot = appointmentTimeSlot == timeSlot
            
            return sameDay && sameTimeSlot
        }
    }

    // MARK: - Doctor Card UI
    private func doctorCard(doctor: Doctor) -> some View {
        HStack(spacing: 15) {
            // Doctor avatar
            ZStack {
                Circle()
                    .fill(Color.mint.opacity(0.15))
                    .frame(width: 60, height: 60)
                
            Image(systemName: "person.fill")
                .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                .foregroundColor(.mint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(doctor.full_name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack(spacing: 20) {
                if let departmentId = doctor.department_id,
                   let department = departmentDetails[departmentId] {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                    Text(department.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "indianrupeesign")
                                .font(.caption)
                        .foregroundColor(.gray)

                            Text("\(Int(department.fees))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        .foregroundColor(.mint)
                        }
                    }
                }
            }
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.mint)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .mint.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Doctor Details Section View
struct DoctorDetailsSectionView: View {
    let doctor: Doctor
    
    var body: some View {
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
    }
}

// MARK: - Appointment Type Section View
struct AppointmentTypeSectionView: View {
    let types: [AppointmentBookingView.AppointmentType]
    @Binding var selectedType: AppointmentBookingView.AppointmentType?
    
    var body: some View {
        Section(header: Text("Appointment Type")) {
            VStack(spacing: 15) {
                ForEach(types, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                    }) {
                        HStack {
                            Image(systemName: "stethoscope")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color.mint)
                                )
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(type.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Regular consultation with the doctor")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.mint)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedType == type ? Color.mint.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedType == type ? Color.mint : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Time Slot Section View
struct TimeSlotSectionView: View {
    let timeSlots: [String]
    let selectedDate: Date
    @Binding var selectedTimeSlot: String?
    @Binding var showTimeSlotWarning: Bool
    @Binding var timeSlotError: String
    let isTimeSlotAlreadyBooked: (Date, String) -> Bool
    
    var body: some View {
        Section(header: Text("Select Time Slot")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Button(action: {
                            if isTimeSlotAlreadyBooked(selectedDate, slot) {
                                timeSlotError = "You already have an appointment scheduled at this time slot. Please select a different time."
                                showTimeSlotWarning = true
                            } else {
                                selectedTimeSlot = slot
                                showTimeSlotWarning = false
                            }
                        }) {
                            Text(slot)
                                .padding(10)
                                .background(
                                    selectedTimeSlot == slot ?
                                    Color.mint :
                                    isTimeSlotAlreadyBooked(selectedDate, slot) ?
                                    Color.red.opacity(0.2) : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    selectedTimeSlot == slot ?
                                    .white :
                                    isTimeSlotAlreadyBooked(selectedDate, slot) ?
                                    .red : .primary
                                )
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedTimeSlot == slot ? Color.mint :
                                            isTimeSlotAlreadyBooked(selectedDate, slot) ?
                                            Color.red : Color.gray,
                                            lineWidth: 2
                                        )
                                )
                        }
                    }
                }
            }
            
            if showTimeSlotWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(timeSlotError)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 5)
            }
        }
    }
}

// MARK: - Appointment Booking Modal View
struct AppointmentBookingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    let doctor: Doctor
    @Binding var selectedDate: Date
    @Binding var selectedTimeSlot: String?
    @Binding var isBookingAppointment: Bool
    @Binding var bookingError: Error?
    var onBookAppointment: () -> Void
    @Binding var selectedAppointmentType: AppointmentType?
    @State private var showTimeSlotWarning = false
    @State private var timeSlotError = ""
    @State private var showPaymentView = false
    @State private var createdAppointment: Appointment?
    @State private var departmentDetails: Department?
    @State private var hospitalDetails: Hospital?
    @StateObject private var coordinator = NavigationCoordinator.shared
    @Environment(\.rootNavigation) private var rootNavigation
    
    // Appointment Types
    enum AppointmentType: String, CaseIterable {
        case consultation = "Consultation"
    }
    
    private let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM",
        "02:00 PM", "03:00 PM", "04:00 PM"
    ]
    // Time slots for demonstration

    var body: some View {
        NavigationView {
            Form {
                DoctorDetailsSectionView(doctor: doctor)
                
                AppointmentTypeSectionView(
                    types: AppointmentType.allCases,
                    selectedType: $selectedAppointmentType
                )
                
                Section(header: Text("Select Date")) {
                    DatePicker("Appointment Date",
                              selection: $selectedDate,
                              in: Date()...,
                              displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .onChange(of: selectedDate) { oldValue, _ in
                            selectedTimeSlot = nil
                        }
                }
                
                TimeSlotSectionView(
                    timeSlots: timeSlots,
                    selectedDate: selectedDate,
                    selectedTimeSlot: $selectedTimeSlot,
                    showTimeSlotWarning: $showTimeSlotWarning,
                    timeSlotError: $timeSlotError,
                    isTimeSlotAlreadyBooked: isTimeSlotAlreadyBooked
                )
            }
            .navigationTitle("Book Appointment")
            .navigationBarItems(
                trailing: Button(isBookingAppointment ? "Booking..." : "Book") {
                    createAppointmentAndProceed()
                }
                .disabled(
                    selectedTimeSlot == nil ||
                    selectedAppointmentType == nil ||
                    isBookingAppointment
                )
            )
            .alert(isPresented: $showTimeSlotWarning) {
                Alert(
                    title: Text("Time Slot Unavailable"),
                    message: Text(timeSlotError),
                    dismissButton: .default(Text("Choose Another Time"))
                )
            }
        }
        .task {
            await fetchDepartmentAndHospitalDetails()
        }
        .sheet(isPresented: $showPaymentView) {
            if let appointment = createdAppointment,
               let department = departmentDetails,
               let hospital = hospitalDetails {
                NavigationView {
                    PaymentView(
                        appointment: appointment,
                        doctor: doctor,
                        department: department,
                        hospital: hospital
                    )
                }
            }
        }
        .onChange(of: coordinator.shouldDismissToRoot) { oldValue, shouldDismiss in
            print("🔄 AppointmentBookingView: shouldDismissToRoot changed to \(shouldDismiss)")
            if shouldDismiss {
                print("👋 AppointmentBookingView: Dismissing view")
                dismiss()
            }
        }
        .onAppear {
            print("👀 AppointmentBookingView: View appeared")
        }
        .onDisappear {
            print("👋 AppointmentBookingView: View disappeared")
        }
    }
    
    private func fetchDepartmentAndHospitalDetails() async {
        if let departmentId = doctor.department_id {
            // Fetch department details from your data source
            // This is a placeholder - replace with actual implementation
            departmentDetails = Department(
                id: departmentId,
                name: "General Medicine",
                description: "General Medical Department",
                hospital_id: doctor.hospital_id ?? UUID(),
                fees: 2000
            )
            
            if let hospitalId = doctor.hospital_id {
                // Fetch hospital details from your data source
                // This is a placeholder - replace with actual implementation
                hospitalDetails = Hospital(
                    id: hospitalId,
                    name: "City Hospital",
                    address: "123 Main Street",
                    city: "City",
                    state: "State",
                    pincode: "12345",
                    mobile_number: "1234567890",
                    email: "hospital@example.com",
                    license_number: "LIC123",
                    is_active: true
                )
            }
        }
    }
    
    private func createAppointmentAndProceed() {
        guard let department = departmentDetails,
              let hospital = hospitalDetails else {
            return
        }
        
        // Create the appointment
        let newAppointment = Appointment(
            id: UUID(),
            patientId: UUID(), // Replace with actual patient ID
            doctorId: doctor.id,
            date: selectedDate,
            status: .scheduled,
            createdAt: Date(),
            type: selectedAppointmentType == .consultation ? .Consultation : .Consultation
        )
        
        // Store the created appointment
        createdAppointment = newAppointment
        
        // Show payment view
        showPaymentView = true
    }
    
    // Check if a time slot is already booked
    private func isTimeSlotAlreadyBooked(date: Date, slot: String) -> Bool {
        // Get existing appointments
        let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        
        // Create calendar for date comparison
        let calendar = Calendar.current
        
        // Check if any appointment matches the date and time slot
        return savedAppointments.contains { appointment in
            guard let appointmentDate = appointment["date"] as? Date,
                  let appointmentTimeSlot = appointment["timeSlot"] as? String else {
                return false
            }
            
            // Compare dates (same day) and time slot
            let sameDay = calendar.isDate(appointmentDate, inSameDayAs: date)
            let sameTimeSlot = appointmentTimeSlot == slot
            
            return sameDay && sameTimeSlot
        }
    }
}
