import SwiftUI

struct DoctorListView: View {
    let doctors: [Doctor]
    @State private var selectedDoctor: Doctor?
    @State private var showAppointmentBookingModal = false
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: TimeSlot?
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
    @State private var showTimeSlotWarning = false
    @State private var timeSlotError = ""
    
    // Time slots for demonstration
//    private let timeSlots = [
//        "09:00 AM", "10:00 AM", "11:00 AM", 
//        "02:00 PM", "03:00 PM", "04:00 PM"
//    ]
//    
    // Filtered doctors based on search
    private var filteredDoctors: [Doctor] {
        if searchText.isEmpty {
            return doctors
        }
        let searchQuery = searchText.lowercased()
        return doctors.filter { doctor in
            doctor.full_name.lowercased().contains(searchQuery)
        }
    }
    
    // If you need to filter by other properties, you can add them like this:
    private func doctorMatchesSearch(_ doctor: Doctor, _ searchQuery: String) -> Bool {
        let nameMatch = doctor.full_name.lowercased().contains(searchQuery)
        
        // Add other filter conditions if needed
        // let specialtyMatch = doctor.specialty?.lowercased().contains(searchQuery) ?? false
        
        return nameMatch // || specialtyMatch
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(searchText: $searchText)
            
            ScrollView {
                if filteredDoctors.isEmpty {
                    EmptyStateView(
                        searchText: searchText,
                        onClearSearch: { searchText = "" }
                    )
        } else {
                    FilteredDoctorListView(
                        doctors: filteredDoctors,
                        departmentDetails: departmentDetails,
                        onDoctorSelect: { doctor in
                            selectedDoctor = doctor
                            showAppointmentBookingModal = true
                        },
                        searchText: searchText,
                        showTimeSlotWarning: $showTimeSlotWarning,
                        timeSlotError: $timeSlotError
                    )
                }
            }
        }
        .navigationTitle("Select Doctor")
        .background(Color.mint.opacity(0.05))
        .task {
            await loadDepartmentDetails()
        }
        .onChange(of: coordinator.shouldDismissToRoot) { oldValue, shouldDismiss in
            if shouldDismiss {
                dismiss()
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
                    initialDepartmentDetails: departmentDetails[doctor.department_id ?? UUID()],
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
    
    private func loadDepartmentDetails() async {
        for doctor in doctors {
            if let departmentId = doctor.department_id {
                if let department = await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
                    departmentDetails[departmentId] = department
                }
            }
        }
    }
    
    func bookAppointment() {
        guard let timeSlot = selectedTimeSlot,
              let doctor = selectedDoctor,
              let appointmentType = selectedAppointmentType else {
            bookingError = NSError(domain: "AppointmentBooking", 
                                 code: 1, 
                                 userInfo: [NSLocalizedDescriptionKey: "Please select all required fields"])
            return
        }
        
        Task {
            isBookingAppointment = true
            bookingError = nil
            
            do {
                guard let patientId = UserDefaults.standard.string(forKey: "currentPatientId"),
                      let patientUUID = UUID(uuidString: patientId) else {
                    throw NSError(domain: "", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Patient ID not found"])
                }
                
                let appointment = Appointment(
                    id: UUID(),
                    patientId: patientUUID,
                    doctorId: doctor.id,
                    date: timeSlot.startTime,
                    status: .scheduled,
                    createdAt: Date(),
                    type: .Consultation
                )
                
                try await supabaseController.createAppointment(
                    appointment: appointment,
                    timeSlot: timeSlot
                )
                
                await MainActor.run {
                    isBookingAppointment = false
                    showAppointmentBookingModal = false
                    selectedTimeSlot = nil
                    selectedAppointmentType = nil
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    bookingError = error
                    isBookingAppointment = false
                }
            }
        }
    }
}

// MARK: - Search Bar Component
struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
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
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let searchText: String
    let onClearSearch: () -> Void
    
    var body: some View {
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
                            
                Button("Clear Search", action: onClearSearch)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppConfig.buttonColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
    }
}

// MARK: - Doctor Card View
struct DoctorCardView: View {
    let doctor: Doctor
    let departmentDetails: [UUID: Department]
    
    var body: some View {
        HStack(spacing: 15) {
            // Doctor avatar
//            ZStack {
//                Circle()
//                    .fill(Color.mint.opacity(0.15))
//                    .frame(width: 60, height: 60)
                
//            Image(systemName: "person.fill")
//                .resizable()
//                    .scaledToFit()
//                    .frame(width: 28, height: 28)
//                .foregroundColor(.mint)
//            }

            VStack(alignment: .leading, spacing: 6) {
                Text(doctor.full_name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let departmentId = doctor.department_id,
                   let department = departmentDetails[departmentId] {
                    HStack(spacing: 20) {
                        DepartmentInfoView(department: department)
                        FeeInfoView(department: department)
                    }
                }
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppConfig.buttonColor)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor, radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Department Info View
struct DepartmentInfoView: View {
    let department: Department
    
    var body: some View {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                    Text(department.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
    }
}

// MARK: - Fee Info View
struct FeeInfoView: View {
    let department: Department
    
    var body: some View {
                        HStack(spacing: 4) {
                            Image(systemName: "indianrupeesign")
                                .font(.caption)
                        .foregroundColor(.gray)

                            Text("\(Int(department.fees))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                .foregroundColor(AppConfig.buttonColor)
        }
    }
}

// MARK: - Filtered Doctor List View
struct FilteredDoctorListView: View {
    let doctors: [Doctor]
    let departmentDetails: [UUID: Department]
    let onDoctorSelect: (Doctor) -> Void
    let searchText: String
    @Binding var showTimeSlotWarning: Bool
    @Binding var timeSlotError: String
    
    var body: some View {
        VStack {
            if !searchText.isEmpty {
                HStack {
                    Text("Found \(doctors.count) doctor(s)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            
            VStack(spacing: 15) {
                ForEach(doctors) { doctor in
                    Button(action: {
                        if UserDefaults.standard.string(forKey: "currentPatientId") == nil {
                            timeSlotError = "Please log in to book an appointment"
                            showTimeSlotWarning = true
                        } else {
                            onDoctorSelect(doctor)
                        }
                    }) {
                        DoctorCardView(doctor: doctor, departmentDetails: departmentDetails)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Doctor Details Section View
struct DoctorDetailsSectionView: View {
    let doctor: Doctor
    @State private var departmentDetails: Department?
    @StateObject private var supabaseController = SupabaseController()
    
    var body: some View {
        Section(header: Text("Doctor Details")) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(AppConfig.buttonColor)
                VStack(alignment: .leading) {
                    Text(doctor.full_name)
                        .font(.headline)
                    if let department = departmentDetails {
                        Text("Consultation Fee: ₹\(String(format: "%.2f", department.fees))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                }
            }
        }
        .task {
            if let departmentId = doctor.department_id {
                departmentDetails = await supabaseController.fetchDepartmentDetails(departmentId: departmentId)
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
                                .foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(AppConfig.buttonColor)
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
    let selectedDate: Date
    @Binding var selectedTimeSlot: TimeSlot?
    @Binding var showTimeSlotWarning: Bool
    @Binding var timeSlotError: String
    let doctor: Doctor
    @StateObject private var supabaseController = SupabaseController()
    @State private var selectedTime = Date()
    @State private var bookedTimeRanges: [String] = []
    @State private var isLoading = false
    @State private var availableTimeSlots: [TimeSlot] = []
    
    // Time slots from 10:00 to 17:00 with 30 min gaps
    let timeSlotStrings = [
        "10:00", "10:30", 
        "11:00", "11:30", 
        "12:00", "12:30", 
        "13:00", "13:30", 
        "14:00", "14:30", 
        "15:00", "15:30", 
        "16:00", "16:30", 
        "17:00"
    ]
    
    var body: some View {
        Section(header: Text("Select Time")) {
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
                
                // Filter out time slots in the past for the current date
                let filteredTimeSlots = timeSlotStrings.filter { timeString in
                    if Calendar.current.isDateInToday(selectedDate) {
                        // Parse the time string to a date
                        let timeComponents = timeString.split(separator: ":")
                        if timeComponents.count == 2,
                           let hour = Int(timeComponents[0]),
                           let minute = Int(timeComponents[1]) {
                            
                            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                            dateComponents.hour = hour
                            dateComponents.minute = minute
                            
                            if let slotTime = Calendar.current.date(from: dateComponents) {
                                // Only include future time slots
                                return slotTime > Date()
                            }
                        }
                        return false
                    }
                    // Include all time slots for future dates
                    return true
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(filteredTimeSlots, id: \.self) { timeString in
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
                
                if filteredTimeSlots.isEmpty && Calendar.current.isDateInToday(selectedDate) {
                    Text("No available time slots for today. Please select another date.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                
                if let slot = selectedTimeSlot {
                    HStack {
                        Text("Selected time:")
                            .font(.subheadline)
                        Spacer()
                        Text(slot.formattedTimeRange)
                            .font(.subheadline)
                            .foregroundColor(AppConfig.buttonColor)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, 8)
                }
            }
            
            if showTimeSlotWarning {
                WarningMessage(message: timeSlotError)
            }
        }
        .onAppear {
            loadBookedTimeSlots()
        }
        .onChange(of: selectedDate) { oldValue, _ in
            selectedTimeSlot = nil
            bookedTimeRanges = []
            loadBookedTimeSlots()
        }
    }
    
    private func isSelectedTimeString(_ timeString: String) -> Bool {
        guard let slot = selectedTimeSlot else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        
        let timeSlotStartString = formatter.string(from: slot.startTime)
        return timeSlotStartString == timeString
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
        for bookedRange in bookedTimeRanges {
            if bookedRange.contains(timeString) {
                return true
            }
        }
        return false
    }
    
    private func selectTimeFromString(_ timeString: String) {
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
                    timeSlotError = "Cannot select a time slot in the past. Please select a future time."
                    showTimeSlotWarning = true
                    return
                }
                
                // Find the time slot from available slots
                if let existingSlot = availableTimeSlots.first(where: { slot in
                    let calendar = Calendar.current
                    return calendar.compare(slot.startTime, to: slotStart, toGranularity: .minute) == .orderedSame
                }) {
                    selectedTimeSlot = existingSlot
                    showTimeSlotWarning = false
                    return
                }
                
                let slotEnd = Calendar.current.date(byAdding: .minute, value: 30, to: slotStart)!
                let newSlot = TimeSlot(startTime: slotStart, endTime: slotEnd)
                
                // Check availability
                Task {
                    do {
                        let isAvailable = try await supabaseController.checkTimeSlotAvailability(
                            doctorId: doctor.id,
                            timeSlot: newSlot
                        )
                        
                        await MainActor.run {
                            if isAvailable {
                                selectedTimeSlot = newSlot
                                showTimeSlotWarning = false
                            } else {
                                timeSlotError = "This time slot is already booked. Please select a different time."
                                showTimeSlotWarning = true
                            }
                        }
                    } catch {
                        await MainActor.run {
                            timeSlotError = "Error checking time slot availability"
                            showTimeSlotWarning = true
                        }
                    }
                }
            }
        }
    }
    
    private func loadBookedTimeSlots() {
        isLoading = true
        bookedTimeRanges = []
        
        Task {
            do {
                let allSlots = TimeSlot.generateTimeSlots(for: selectedDate)
                let fetchedAvailableSlots = try await supabaseController.getAvailableTimeSlots(
                    doctorId: doctor.id,
                    date: selectedDate
                )
                
                // Filter out slots that are in the past if selected date is today
                let currentDate = Date()
                let filteredAvailableSlots = fetchedAvailableSlots.filter { slot in
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
                    "\(formatter.string(from: slot.startTime)) - \(formatter.string(from: slot.endTime))"
                }
                
                await MainActor.run {
                    self.availableTimeSlots = filteredAvailableSlots
                    bookedTimeRanges = bookedRanges
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    timeSlotError = "Error loading booked time slots"
                    showTimeSlotWarning = true
                    isLoading = false
                }
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
    @Binding var selectedTimeSlot: TimeSlot?
    @Binding var isBookingAppointment: Bool
    @Binding var bookingError: Error?
    @State private var departmentDetails: Department?
    var onBookAppointment: () -> Void
    @Binding var selectedAppointmentType: AppointmentType?
    @State private var showTimeSlotWarning = false
    @State private var timeSlotError = ""
    @State private var showPaymentView = false
    @State private var createdAppointment: Appointment?
    @State private var hospitalDetails: Hospital?
    @StateObject private var coordinator = NavigationCoordinator.shared
    @Environment(\.rootNavigation) private var rootNavigation
    @StateObject private var supabaseController = SupabaseController()
    
    // Appointment Types
    enum AppointmentType: String, CaseIterable {
        case consultation = "Consultation"
    }
    
    // Remove hardcoded timeSlots and fetch from your data source if needed
    @State private var availableTimeSlots: [TimeSlot] = []
    
    // Add an initializer to set the initial department details
    init(doctor: Doctor,
         selectedDate: Binding<Date>,
         selectedTimeSlot: Binding<TimeSlot?>,
         isBookingAppointment: Binding<Bool>,
         bookingError: Binding<Error?>,
         initialDepartmentDetails: Department?,
         onBookAppointment: @escaping () -> Void,
         selectedAppointmentType: Binding<AppointmentType?>) {
        self.doctor = doctor
        self._selectedDate = selectedDate
        self._selectedTimeSlot = selectedTimeSlot
        self._isBookingAppointment = isBookingAppointment
        self._bookingError = bookingError
        self._departmentDetails = State(initialValue: initialDepartmentDetails)
        self.onBookAppointment = onBookAppointment
        self._selectedAppointmentType = selectedAppointmentType
    }

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
                              in: Date()...Calendar.current.date(byAdding: .day, value: 28, to: Date())!,
                              displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .tint(AppConfig.buttonColor)
                        .environment(\.timeZone, TimeZone(identifier: "Asia/Kolkata")!)
                        .onChange(of: selectedDate) { oldValue, _ in
                            selectedTimeSlot = nil
                        }
                }
                
                TimeSlotSectionView(
                    selectedDate: selectedDate,
                    selectedTimeSlot: $selectedTimeSlot,
                    showTimeSlotWarning: $showTimeSlotWarning,
                    timeSlotError: $timeSlotError,
                    doctor: doctor
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
            await loadAvailableTimeSlots()
            await fetchDepartmentAndHospitalDetails()
        }
        .fullScreenCover(isPresented: $showPaymentView, onDismiss: {
            // Only dismiss the booking view if payment is completed or canceled
            dismiss()
        }) {
            if let appointment = createdAppointment,
               let department = departmentDetails,
               let hospital = hospitalDetails {
                    PaymentView(
                        appointment: appointment,
                        doctor: doctor,
                        department: department,
                        hospital: hospital
                    )
            }
        }
        .onChange(of: coordinator.shouldDismissToRoot) { oldValue, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
    
    private func fetchDepartmentAndHospitalDetails() async {
        if let departmentId = doctor.department_id {
            do {
                // Use existing method from SupabaseController
                if let department = await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
                    departmentDetails = department
                }
            
            if let hospitalId = doctor.hospital_id {
                    // Use existing method from SupabaseController
                    hospitalDetails = try await supabaseController.fetchHospitalById(hospitalId: hospitalId)
                }
            } catch {
                print("Error fetching details: \(error)")
            }
        }
    }
    
    private func createAppointmentAndProceed() {
        guard let selectedSlot = selectedTimeSlot else {
            timeSlotError = "Please select a time slot"
            showTimeSlotWarning = true
            return
        }
        
        guard let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
              let patientId = UUID(uuidString: patientIdString) else {
            timeSlotError = "Patient ID not found. Please log in again."
            showTimeSlotWarning = true
            return
        }
        
        Task {
            isBookingAppointment = true
            do {
        let newAppointment = Appointment(
            id: UUID(),
                    patientId: patientId,
            doctorId: doctor.id,
                    date: selectedSlot.startTime,
            status: .scheduled,
            createdAt: Date(),
                    type: .Consultation
                )
                
                // Pass both the appointment and timeSlot
                try await supabaseController.createAppointment(
                    appointment: newAppointment,
                    timeSlot: selectedSlot
                )
                
                await MainActor.run {
                    isBookingAppointment = false
                    
                    // Set the created appointment for payment view
        createdAppointment = newAppointment
        
                    // Show the payment view instead of dismissing
        showPaymentView = true
                }
            } catch {
                await MainActor.run {
                    timeSlotError = "Error booking appointment: \(error.localizedDescription)"
                    showTimeSlotWarning = true
                    isBookingAppointment = false
                }
            }
        }
    }
    
    private func loadAvailableTimeSlots() async {
        do {
            availableTimeSlots = try await supabaseController.getAvailableTimeSlots(
                doctorId: doctor.id,
                date: selectedDate
            )
        } catch {
            print("Error loading time slots: \(error)")
            availableTimeSlots = []
        }
    }
}

// Add this struct if it's missing
struct WarningMessage: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
        }
        .padding(.vertical, 5)
    }
}
