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
                        HomeTabView(
                            selectedHospital: $selectedHospital,
                            departments: $departments
                        )
                        .padding(.top, 80) // Increase padding to account for sticky header
                    }
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                    
                    // MARK: - Appointments Tab
                    AppointmentsTabView()
                        .tabItem {
                            Label("Appointments", systemImage: "calendar")
                        }
                        .tag(1)
                    
                    // MARK: - Records Tab
                    RecordsTabView(selectedHospitalId: $selectedHospitalId)
                        .tabItem {
                            Label("Records", systemImage: "doc.text.fill")
                        }
                        .tag(2)
                    
                    // MARK: - Invoices Tab
                    InvoicesTabView(selectedHospitalId: $selectedHospitalId)
                        .tabItem {
                            Label("Invoices", systemImage: "doc.text.fill")
                        }
                        .tag(3)
                }
                
                // Sticky header only visible in home tab
                if selectedTab == 0 {
                    VStack {
                        Text("Hi, \(patient.fullname)")
                            .font(.title)  // Changed from .largeTitle to .title
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 15) // Adjusted top padding
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
                ToolbarItem(placement: .navigationBarTrailing) {
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

