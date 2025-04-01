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
        }
        
        let searchQuery = searchText.lowercased()
            return doctors.filter { doctor in
            // Break down the filtering logic into simpler steps
            let nameMatch = doctor.full_name.lowercased().contains(searchQuery)
            return nameMatch
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
                        searchText: searchText
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
    
    // Book appointment function
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
                // Create the appointment using actual API call
                let appointment = Appointment(
                    id: UUID(),
                    patientId: UUID(), // Replace with actual patient ID
                    doctorId: doctor.id,
                    date: selectedDate,
                    status: .scheduled,
                    createdAt: Date(),
                    type: .Consultation
                )
                
                // Save the appointment to Supabase
                // Add the appropriate method to SupabaseController to save appointments
                // try await supabaseController.createAppointment(appointment)
                
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
                    Button(action: { onDoctorSelect(doctor) }) {
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
    let timeSlots: [String]
    let selectedDate: Date
    @Binding var selectedTimeSlot: String?
    @Binding var showTimeSlotWarning: Bool
    @Binding var timeSlotError: String
    let doctor: Doctor
    @StateObject private var supabaseController = SupabaseController()
    
    var body: some View {
        Section(header: Text("Select Time Slot")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Button(action: {
                            checkAndSelectTimeSlot(slot)
                        }) {
                            Text(slot)
                                .padding(10)
                                .background(
                                    selectedTimeSlot == slot ?
                                    Color.mint :
                                    Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    selectedTimeSlot == slot ?
                                    .white : .primary
                                )
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedTimeSlot == slot ? Color.mint : Color.gray,
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
    
    private func checkAndSelectTimeSlot(_ slot: String) {
        Task {
            do {
                let isAvailable = try await supabaseController.checkTimeSlotAvailability(
                    doctorId: doctor.id,
                    date: selectedDate,
                    timeSlot: slot
                )
                
                await MainActor.run {
                    if isAvailable {
                        selectedTimeSlot = slot
                        showTimeSlotWarning = false
                    } else {
                        timeSlotError = "This time slot is already booked. Please select another time."
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

// MARK: - Appointment Booking Modal View
struct AppointmentBookingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    let doctor: Doctor
    @Binding var selectedDate: Date
    @Binding var selectedTimeSlot: String?
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
    @State private var availableTimeSlots: [String] = []
    
    // Add an initializer to set the initial department details
    init(doctor: Doctor,
         selectedDate: Binding<Date>,
         selectedTimeSlot: Binding<String?>,
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
                        .onChange(of: selectedDate) { _ in
                            selectedTimeSlot = nil
                        }
                }
                
                TimeSlotSectionView(
                    timeSlots: availableTimeSlots,
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
        guard let department = departmentDetails,
              let hospital = hospitalDetails,
              let timeSlot = selectedTimeSlot,
              let appointmentType = selectedAppointmentType else {
            return
        }
        
        Task {
            do {
                // Get current patient ID from UserDefaults or your auth system
                guard let patientId = UserDefaults.standard.string(forKey: "currentPatientId"),
                      let patientUUID = UUID(uuidString: patientId) else {
                    throw NSError(domain: "", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Patient ID not found"])
        }
        
        // Create the appointment
        let newAppointment = Appointment(
            id: UUID(),
                    patientId: patientUUID,
            doctorId: doctor.id,
            date: selectedDate,
            status: .scheduled,
            createdAt: Date(),
                    type: .Consultation
        )
        
                // Store the created appointment using Supabase
                try await supabaseController.createAppointment(appointment: newAppointment)
                
                // Store the created appointment for payment view
        createdAppointment = newAppointment
        
                await MainActor.run {
        // Show payment view
        showPaymentView = true
    }
            } catch {
                await MainActor.run {
                    bookingError = error
                    showTimeSlotWarning = true
                    timeSlotError = error.localizedDescription
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
