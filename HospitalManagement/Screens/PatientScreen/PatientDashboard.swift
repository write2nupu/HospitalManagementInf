import SwiftUI

class HospitalManagementTestViewModel: ObservableObject {
    @Published var showUserProfile = false
}

// MARK: - Patient Dashboard View
struct PatientDashboard: View {
    private var viewModel: HospitalManagementViewModel = .init()
    @State private var patient: Patient
    @State private var showProfile = false
    @StateObject private var supabaseController = SupabaseController()
    @State private var departments: [Department] = []
    @State private var isLoadingDepartments = false
    @AppStorage("selectedHospitalId") private var selectedHospitalId: String = ""
    @State private var selectedTab = 0
    @State private var selectedHospital: Hospital?
    @State private var isHospitalSelectionPresented = false
    
    init(patient: Patient) {
        _patient = State(initialValue: patient)
        // Clear any pre-existing hospital selection
        UserDefaults.standard.removeObject(forKey: "selectedHospitalId")
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                TabView(selection: $selectedTab) {
                    // MARK: - Home Tab
                    ZStack(alignment: .top) {
                        // Main content starts below the header
                        homeTabView
                            .padding(.top, 50) // Add padding to account for sticky header
                    }
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                    
                    // MARK: - Appointments Tab
                    appointmentsTabView
                        .tabItem {
                            Label("Appointments", systemImage: "calendar")
                        }
                        .tag(1)
                    
                    // MARK: - Records Tab
                    recordsTabView
                        .tabItem {
                            Label("Records", systemImage: "doc.text.fill")
                        }
                        .tag(2)
                    
                    // MARK: - Invoices Tab
                    invoicesTabView
                        .tabItem {
                            Label("Invoices", systemImage: "doc.text.fill")
                        }
                        .tag(3)
                }
                
                // Sticky header only visible in home tab
                if selectedTab == 0 {
                    VStack {
                        Text("Hi, \(patient.fullname)")
                            .font(.largeTitle)
                    .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                            .padding(.top, 10)
                            .background(Color(.systemBackground))
                        
                        Divider()
                    }
                    .background(Color(.systemBackground))
                    .zIndex(1) // Ensure header appears on top
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle(
                selectedTab == 0 ? "" : // Empty for home tab since we use custom header
                selectedTab == 1 ? "" : // Empty for appointments tab since we use custom header
                selectedTab == 2 ? "" : // Empty for records tab since we use custom header
                ""                      // Empty for invoices tab since we use custom header
            )
            .navigationBarTitleDisplayMode(.inline) // Use inline mode for all tabs since we have custom headers
            .toolbar {
                // Profile Picture in the Top Right
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppConfig.buttonColor)
                    }
                    .sheet(isPresented: $showProfile) {
                        ProfileView(patient: $patient)
                    }
                }
            }
            .onAppear {
                if !selectedHospitalId.isEmpty {
                    loadDepartments()
                    fetchSelectedHospital()
                }
            }
            .onChange(of: selectedHospitalId) { newValue in
                if !newValue.isEmpty {
                    loadDepartments()
                    fetchSelectedHospital()
                } else {
                    selectedHospital = nil
                }
            }
        }
    }
    
    // MARK: - Emergency Assistance View
    struct EmergencyAssistanceView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var patientName = ""
        @State private var patientAge = ""
        @State private var emergencyDescription = ""
        @State private var isBookingEmergency = false
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emergency Assistance")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("Provide necessary details for immediate medical help")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Patient Information Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Patient Details")
                            .font(.headline)
                            .foregroundColor(AppConfig.fontColor)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Full Name", text: $patientName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                            
                            TextField("Age", text: $patientAge)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Emergency Description Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Emergency Description")
                            .font(.headline)
                            .foregroundColor(AppConfig.fontColor)
                        
                        TextEditor(text: $emergencyDescription)
                            .frame(height: 150)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .placeholder("Describe your medical emergency...", when: emergencyDescription.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    // Book Emergency Button
                    Button(action: {
                        bookEmergencyAssistance()
                    }) {
                        HStack {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.white)
                            
                            Text(isBookingEmergency ? "Booking..." : "Book Emergency Assistance")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canBookEmergency ? Color.red : Color.gray)
                        )
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    }
                    .disabled(!canBookEmergency || isBookingEmergency)
                }
                .padding(.vertical)
            }
            .navigationBarBackButtonHidden(false)
        }
        
        // Computed property to check if emergency can be booked
        private var canBookEmergency: Bool {
            !patientName.isEmpty && 
            !patientAge.isEmpty && 
            !emergencyDescription.isEmpty
        }
        
        private func bookEmergencyAssistance() {
            guard canBookEmergency else { return }
            
            isBookingEmergency = true
            
            // Simulate async booking process
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Prepare emergency appointment details
                let emergencyAppointmentDetails: [String: Any] = [
                    "id": UUID().uuidString,
                    "doctorName": "Emergency Assistance",
                    "appointmentType": "Emergency",
                    "patientName": patientName,
                    "patientAge": patientAge,
                    "emergencyDescription": emergencyDescription,
                    "date": Date(),
                    "timeSlot": "Immediate",
                    "status": "Booked",
                    "timestamp": Date()
                ]
                
                // Save emergency appointment details to UserDefaults
                var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
                savedAppointments.append(emergencyAppointmentDetails)
                UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
                
                // Reset and dismiss
                isBookingEmergency = false
                dismiss()
            }
        }
    }
    
    // MARK: - Home Tab View
    private var homeTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Subtitle Section
                Text("Let's take care of your health.")
                    .font(.body)
                    .foregroundColor(AppConfig.fontColor)
                    .padding(.horizontal)
                
                // MARK: - Quick Actions Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Quick Action")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.fontColor)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: HospitalListView()) {
                        VStack(spacing: 12) {
                            if let hospital = selectedHospital {
                                // Selected Hospital Card View
                                HStack(alignment: .center, spacing: 15) {
                                    Image(systemName: "building.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(AppConfig.buttonColor)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(hospital.name)
                                            .font(.headline)
                                            .foregroundColor(AppConfig.fontColor)
                                            .fontWeight(.semibold)
                                        
                                        Text("\(hospital.city), \(hospital.state)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("Change")
                                        .font(.caption)
                                        .foregroundColor(AppConfig.buttonColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(AppConfig.buttonColor, lineWidth: 1)
                                        )
                                }
                            } else {
                                // No Hospital Selected View
                                HStack {
                                    Image(systemName: "building.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppConfig.buttonColor)
                                    
                                    Text("Select Hospital")
                                        .font(.title3)
                                        .foregroundColor(AppConfig.fontColor)
                                        .fontWeight(.regular)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Only show Services and Departments if a hospital is selected
                if let hospital = selectedHospital {
                    // MARK: - Latest Appointment Section
                    if let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]], !savedAppointments.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Latest Appointment")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppConfig.fontColor)
                                .padding(.horizontal)
                            
                            // Get the most recent appointment
                            let latestAppointment = savedAppointments.max { 
                                ($0["timestamp"] as? Date) ?? Date.distantPast < 
                                    ($1["timestamp"] as? Date) ?? Date.distantPast 
                            }
                            
                            if let appointment = latestAppointment {
                                NavigationLink(destination: AppointmentDetailsView(appointmentDetails: appointment)) {
                                    HStack(spacing: 15) {
                                        Image(systemName: appointment["appointmentType"] as? String == "Emergency" ? "cross.case.fill" : "calendar.badge.plus")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(
                                                appointment["appointmentType"] as? String == "Emergency" ? Color.red : Color.mint
                                            )
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(appointment["doctorName"] as? String ?? "Appointment")
                                                .font(.headline)
                                                .foregroundColor(
                                                    (appointment["appointmentType"] as? String) == "Emergency" ? 
                                                        .red : .mint
                                                )
                                            
                                            Text("Immediate medical help")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(
                                                (appointment["appointmentType"] as? String) == "Emergency" ? 
                                                    .red : .mint
                                            )
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(
                                                (appointment["appointmentType"] as? String) == "Emergency" ? 
                                                Color.red.opacity(0.1) : Color.mint.opacity(0.1)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    
                    // MARK: - Emergency Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Emergency")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: EmergencyAssistanceView()) {
                            HStack(spacing: 15) {
                                Image(systemName: "cross.case.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Emergency Assistance")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    
                                    Text("Immediate medical help")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.red.opacity(0.1))
                                    .shadow(color: Color.red.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                    
                    // MARK: - Services Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Services")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        HStack(spacing: 15) {
                            // Book Appointment Card
                            NavigationLink(destination: DepartmentListView()) {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppConfig.buttonColor)
                                    
                                    Text("Book\nAppointment")
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(AppConfig.fontColor)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                            }
                            
                            // Book Bed Card
                            NavigationLink(destination: Text("Bed Booking Coming Soon")) {
                                VStack(spacing: 12) {
                                    Image(systemName: "bed.double.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppConfig.buttonColor)
                                    
                                    Text("Book\nBed")
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(AppConfig.fontColor)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Departments Section
                    HStack {
                        Text("Departments")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                        
                        Spacer()
                        
                        NavigationLink(destination: DepartmentListView()) {
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.buttonColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(departments.prefix(5)) { department in
                                NavigationLink(destination: DoctorListView(doctors: [])) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(department.name)
                                            .font(.headline)
                                            .foregroundColor(.mint)
                                            .lineLimit(1)
                                        
                                        if let description = department.description {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .lineLimit(2)
                                        }
                                    }
                                    .frame(width: 150, height: 100)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(AppConfig.backgroundColor)
    }
    
    // MARK: - Appointments Tab View
    private var appointmentsTabView: some View {
        ZStack(alignment: .top) {
            Group {
                if let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]], !savedAppointments.isEmpty {
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
                        
                        // List of appointments with padding to account for the sticky header
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(savedAppointments.indices, id: \.self) { index in
                                    VStack(spacing: 0) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(savedAppointments[index]["doctorName"] as? String ?? "")
                                                    .font(.headline)
                                                
                                                HStack(spacing: 10) {
                                                    Image(systemName: "calendar")
                                                        .foregroundColor(.gray)
                                                    Text(formatAppointmentDate(savedAppointments[index]["date"]))
                                                        .font(.subheadline)
                                                    
                                                    Image(systemName: "clock")
                                                        .foregroundColor(.gray)
                                                    Text(savedAppointments[index]["timeSlot"] as? String ?? "")
                                                        .font(.subheadline)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Text(savedAppointments[index]["appointmentType"] as? String ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(
                                                    (savedAppointments[index]["appointmentType"] as? String) == "Emergency" ? 
                                                        .red : .mint
                                                )
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .background(Color(.systemBackground))
                                        
                                        Divider()
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            deleteAppointment(at: IndexSet(integer: index))
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("No Appointments")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Book your first appointment to see it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: DepartmentListView()) {
                            Text("Book Appointment")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.mint)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(.top, 50) // Add space at the top for the sticky header
            
            // Sticky header
            VStack(spacing: 0) {
                Text("Appointments")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color(.systemBackground))
                
                Divider()
            }
            .background(Color(.systemBackground))
            .zIndex(1) // Ensure header appears on top
        }
    }
    
    // Comprehensive date formatting method
    private func formatAppointmentDate(_ dateObj: Any?) -> String {
        // Create a date formatter
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        // Simplified date extraction
        func extractDate(_ obj: Any?) -> Date? {
            // Direct Date casting
            if let date = obj as? Date { return date }
            
            // Dictionary date extraction
            if let dict = obj as? [String: Any] {
                let keys = ["date", "timestamp", "createdAt"]
                for key in keys {
                    if let date = dict[key] as? Date { return date }
                }
            }
            
            return nil
        }
        
        // Extract and format date
        guard let date = extractDate(dateObj) else { return "N/A" }
        return formatter.string(from: date)
    }
    
    // Function to delete an appointment
    private func deleteAppointment(at offsets: IndexSet) {
        var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
        savedAppointments.remove(atOffsets: offsets)
        UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
    }
    
    // MARK: - Records Tab View
    private var recordsTabView: some View {
        ZStack(alignment: .top) {
            Group {
                if selectedHospitalId.isEmpty {
                    noHospitalSelectedView
                        .padding(.top, 50) // Add space at the top for the sticky header
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Medical Records Section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Medical Records")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppConfig.fontColor)
                                    .padding(.horizontal)
                                
                                // Placeholder for medical records
                                recordCategoryCard(title: "Lab Reports", iconName: "cross.case.fill", count: 0)
                                recordCategoryCard(title: "Prescriptions", iconName: "pill.fill", count: 0)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .padding(.top, 50) // Add space at the top for the sticky header
                    }
                    .background(AppConfig.backgroundColor)
                }
            }
            
            // Sticky header for Records tab
            VStack(spacing: 0) {
                Text("Medical Records")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color(.systemBackground))
                
                Divider()
            }
            .background(Color(.systemBackground))
            .zIndex(1) // Ensure header appears on top
        }
    }
    
    // MARK: - Invoices Tab View
    private var invoicesTabView: some View {
        ZStack(alignment: .top) {
            Group {
                if selectedHospitalId.isEmpty {
                    noHospitalSelectedView
                        .padding(.top, 50) // Add space at the top for the sticky header
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Invoices Section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Billing Invoices")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppConfig.fontColor)
                                    .padding(.horizontal)
                                
                                // Placeholder for invoices
                                invoiceCard(
                                    title: "Hospital Consultation",
                                    date: Date(),
                                    amount: 500.00,
                                    status: .paid
                                )
                                
                                invoiceCard(
                                    title: "Lab Tests",
                                    date: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
                                    amount: 1200.00,
                                    status: .pending
                                )
                            }
                        }
                        .padding(.vertical)
                        .padding(.top, 50) // Add space at the top for the sticky header
                    }
                    .background(AppConfig.backgroundColor)
                }
            }
            
            // Sticky header for Invoices tab
            VStack(spacing: 0) {
                Text("Invoices")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color(.systemBackground))
                
                Divider()
            }
            .background(Color(.systemBackground))
            .zIndex(1) // Ensure header appears on top
        }
    }
    
    // MARK: - Invoice Card Helper
    private enum InvoiceStatus {
        case paid
        case pending
        case overdue
    }
    
    private func invoiceCard(title: String, date: Date, amount: Double, status: InvoiceStatus) -> some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 24))
                .foregroundColor(statusColor(status))
                .frame(width: 50, height: 50)
                .background(statusColor(status).opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
                
                Text(formatInvoiceDate(date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("₹\(String(format: "%.2f", amount))")
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
                
                Text(statusText(status))
                    .font(.caption)
                    .foregroundColor(statusColor(status))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
    
    private func formatInvoiceDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .paid: return .green
        case .pending: return .orange
        case .overdue: return .red
        }
    }
    
    private func statusText(_ status: InvoiceStatus) -> String {
        switch status {
        case .paid: return "Paid"
        case .pending: return "Pending"
        case .overdue: return "Overdue"
        }
    }
    
    // MARK: - Helper Views
    private var noHospitalSelectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(AppConfig.buttonColor.opacity(0.5))
            
            Text("No Hospital Selected")
                .font(.title3)
                .foregroundColor(AppConfig.fontColor)
            
            Text("Please select a hospital to view your information")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                selectedTab = 0
            }) {
                Text("Go to Home")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConfig.buttonColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 50)
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Record Detail View
    private struct RecordDetailView: View {
        let title: String
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("No records available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(AppConfig.backgroundColor)
        }
    }
    
    private func recordCategoryCard(title: String, iconName: String, count: Int) -> some View {
        NavigationLink(destination: RecordDetailView(title: title)) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(AppConfig.buttonColor)
                    .frame(width: 50, height: 50)
                    .background(AppConfig.buttonColor.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    Text("\(count) records")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(.vertical, 5)
        }
    }
    
    private func loadDepartments() {
        isLoadingDepartments = true
        departments = []
        
        guard let hospitalId = UUID(uuidString: selectedHospitalId) else {
            isLoadingDepartments = false
            return
        }
        
        Task {
            do {
                let fetchedDepartments = try await supabaseController.fetchHospitalDepartments(hospitalId: hospitalId)
                DispatchQueue.main.async {
                    departments = fetchedDepartments
                    isLoadingDepartments = false
                }
            } catch {
                print("Error loading departments: \(error)")
                DispatchQueue.main.async {
                    isLoadingDepartments = false
                }
            }
        }
    }
    
    private func fetchSelectedHospital() {
        guard let hospitalId = UUID(uuidString: selectedHospitalId) else {
            selectedHospital = nil
            return
        }
        
        Task {
            do {
                let hospitals = await supabaseController.fetchHospitals()
                if let hospital = hospitals.first(where: { $0.id == hospitalId }) {
                    DispatchQueue.main.async {
                        selectedHospital = hospital
                    }
                }
            } catch {
                print("Error fetching selected hospital: \(error)")
            }
        } 
    }
    
    // MARK: - Appointment Details View
    struct AppointmentDetailsView: View {
        let appointmentDetails: [String: Any]
        
        // Static method for date formatting
        private static func formatAppointmentDate(_ dateObj: Any?) -> String {
            // Create a date formatter
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            
            // Simplified date extraction
            func extractDate(_ obj: Any?) -> Date? {
                // Direct Date casting
                if let date = obj as? Date { return date }
                
                // Dictionary date extraction
                if let dict = obj as? [String: Any] {
                    let keys = ["date", "timestamp", "createdAt"]
                    for key in keys {
                        if let date = dict[key] as? Date { return date }
                    }
                }
                
                return nil
            }
            
            // Extract and format date
            guard let date = extractDate(dateObj) else { return "N/A" }
            return formatter.string(from: date)
        }
        
        var appointmentType: String {
            appointmentDetails["appointmentType"] as? String ?? ""
        }
        
        var doctorName: String {
            appointmentDetails["doctorName"] as? String ?? "Appointment"
        }
        
        var appointmentIcon: String {
            appointmentType == "Emergency" ? "cross.case.fill" : "calendar.badge.plus"
        }
        
        var appointmentIconColor: Color {
            appointmentType == "Emergency" ? .red : .mint
        }
        
        var appointmentBackgroundColor: Color {
            appointmentType == "Emergency" ? Color.red.opacity(0.1) : Color.mint.opacity(0.1)
        }
        
        var appointmentTextColor: Color {
            appointmentType == "Emergency" ? .red : .mint
        }
        
        var emergencyDescription: String? {
            appointmentDetails["emergencyDescription"] as? String
        }
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Appointment Type Header
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 15) {
                            Image(systemName: appointmentIcon)
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .padding()
                                .background(appointmentIconColor)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(doctorName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(appointmentTextColor)
                                
                                Text(appointmentType)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(appointmentBackgroundColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // Appointment Details Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Appointment Details")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                        
                        VStack(spacing: 15) {
                            DetailRow(icon: "calendar", title: "Date", value: Self.formatAppointmentDate(appointmentDetails["date"]))
                            Divider()
                            DetailRow(icon: "clock", title: "Time Slot", value: appointmentDetails["timeSlot"] as? String ?? "N/A")
                            
                            if let patientName = appointmentDetails["patientName"] as? String {
                                Divider()
                                DetailRow(icon: "person", title: "Patient Name", value: patientName)
                            }
                            
                            if let patientAge = appointmentDetails["patientAge"] as? String {
                                Divider()
                                DetailRow(icon: "number", title: "Patient Age", value: patientAge)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Emergency Description (if applicable)
                    if let emergencyDescription = emergencyDescription, !emergencyDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Emergency Description")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppConfig.fontColor)
                            
                            Text(emergencyDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Appointment Details")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppConfig.backgroundColor)
        }
    }
    
    // Nested Detail Row View
    private struct DetailRow: View {
        let icon: String
        let title: String
        let value: String
        
        var body: some View {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .foregroundColor(AppConfig.buttonColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.body)
                        .foregroundColor(AppConfig.fontColor)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PatientDashboard(patient: Patient(
        id: UUID(),
        fullName: "Tarun",
        gender: "male",
        dateOfBirth: Date(),
        contactNo: "1234567898",
        email: "tarun@gmail.com"
    ))
}

// MARK: - TextEditor Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder then: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            then()
                .opacity(shouldShow ? 1 : 0)
            
            self
        }
    }
    
    func placeholder(
        _ text: String,
        when shouldShow: Bool,
        alignment: Alignment = .leading
    ) -> some View {
        placeholder(when: shouldShow, alignment: alignment) {
            Text(text)
                .foregroundColor(.gray)
        }
    }
}


