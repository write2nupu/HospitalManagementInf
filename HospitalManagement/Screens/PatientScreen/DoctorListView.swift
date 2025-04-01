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
        .onChange(of: coordinator.shouldDismissToRoot) { shouldDismiss in
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
                    .background(Color.mint)
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
                .foregroundColor(.mint)
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
                    .foregroundColor(.mint)
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
    let selectedDate: Date
    @Binding var selectedTimeSlot: TimeSlot?
    @Binding var showTimeSlotWarning: Bool
    @Binding var timeSlotError: String
    let doctor: Doctor
    @StateObject private var supabaseController = SupabaseController()
    @State private var availableTimeSlots: [TimeSlot] = []
    @State private var isLoading = false
    
    var body: some View {
        Section(header: Text("Select Time Slot")) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(availableTimeSlots) { slot in
                        TimeSlotButton(
                            slot: slot,
                            isSelected: selectedTimeSlot == slot,
                            action: { selectedTimeSlot = slot }
                        )
                    }
                }
                .padding(.vertical, 5)
            }
            
            if showTimeSlotWarning {
                WarningMessage(message: timeSlotError)
            }
        }
        .onAppear {
            loadAvailableTimeSlots()
        }
        .onChange(of: selectedDate) { _ in
            loadAvailableTimeSlots()
        }
    }
    
    private func loadAvailableTimeSlots() {
        isLoading = true
        Task {
            do {
                let slots = try await supabaseController.getAvailableTimeSlots(
                    doctorId: doctor.id,
                    date: selectedDate
                )
                await MainActor.run {
                    availableTimeSlots = slots
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    timeSlotError = "Error loading time slots: \(error.localizedDescription)"
                    showTimeSlotWarning = true
                    isLoading = false
                }
            }
        }
    }
}

struct TimeSlotButton: View {
    let slot: TimeSlot
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(slot.formattedTimeRange)
                .font(.footnote)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.mint.opacity(0.1) : Color.white)
                )
                .foregroundColor(isSelected ? .mint : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.mint : Color.gray.opacity(0.3), lineWidth: 1)
                )
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
                              in: Date()...,
                              displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .environment(\.timeZone, TimeZone(identifier: "Asia/Kolkata")!)
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
        .onChange(of: coordinator.shouldDismissToRoot) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
    
    private func fetchDepartmentAndHospitalDetails() async {
        if let departmentId = doctor.department_id {
            do {
                // Use existing method from SupabaseController
                if let department = try await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
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
                    dismiss()
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
