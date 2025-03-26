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
            TabView(selection: $selectedTab) {
                // MARK: - Home Tab
                homeTabView
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
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle(selectedTab == 0 ? "Hi, \(patient.fullname)" : selectedTab == 1 ? "Appointments" : "Medical Records")
            .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - Home Tab View
    private var homeTabView: some View {
        VStack(alignment: .leading, spacing: 0) {
                // MARK: - Subtitle Section
                Text("Let's take care of your health.")
                    .font(.body)
                    .foregroundColor(AppConfig.fontColor)
                    .padding(.horizontal)
                .padding(.top)
                
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
                // MARK: - Services Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Services")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.fontColor)
                        .padding(.horizontal)
                        .padding(.top, 15)
                    
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
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
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
            
            Spacer()
        }
        .background(AppConfig.backgroundColor)
    }
    
    // MARK: - Appointments Tab View
    private var appointmentsTabView: some View {
        Group {
            if let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]], !savedAppointments.isEmpty {
                List {
                    Section(header: Text("Upcoming Appointments").textCase(.uppercase).font(.caption).foregroundColor(.secondary)) {
                        ForEach(savedAppointments.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(savedAppointments[index]["doctorName"] as? String ?? "")
                                        .font(.headline)
                                    
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.gray)
                                        Text(formatAppointmentDate(savedAppointments[index]["date"] as? Date))
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
                        }
                        .onDelete(perform: deleteAppointment)
                    }
                }
                .listStyle(InsetGroupedListStyle())
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
    }
    
    // Helper function to format appointment date
    private func formatAppointmentDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
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
        ScrollView {
            VStack(spacing: 20) {
                if selectedHospitalId.isEmpty {
                    noHospitalSelectedView
                } else {
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
                        recordCategoryCard(title: "Imaging & Scans", iconName: "lungs.fill", count: 0)
                        recordCategoryCard(title: "Discharge Summaries", iconName: "doc.text.fill", count: 0)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            }
            .background(AppConfig.backgroundColor)
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
    
    private func recordCategoryCard(title: String, iconName: String, count: Int) -> some View {
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
