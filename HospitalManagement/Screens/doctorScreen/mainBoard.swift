import SwiftUI

struct mainBoard: View {
    @StateObject private var supabaseController = SupabaseController()
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var showProfile = false
    @State private var doctor: Doctor?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Track selected tab
    @State private var selectedTab: Int?
    
    // Titles for different screens
    var tabTitles = ["Dashboard", "Appointments", "Patients"]
    
    // Dynamic Title based on Selected Tab
    var dynamicTitle: String {
        if selectedTab == 0 {
            return "Hi, \(doctor?.full_name.components(separatedBy: " ").first ?? "Doctor")"
        } else {
            return tabTitles[selectedTab ?? 0]
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading...")
                } else if let error = errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await fetchDoctorDetails()
                            }
                        }
                    }
                } else  {
                    TabView(selection: $selectedTab) {
                        DoctorDashBoard()
                            .tag(0)
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                            .onAppear { selectedTab = 0 }

                        AppointmentView()
                            .tag(1)
                            .tabItem {
                                Label("Appointments", systemImage: "calendar")
                            }
                            .onAppear { selectedTab = 1 }

                        PatientView()
                            .tag(2)
                            .tabItem {
                                Label("Patients", systemImage: "person.fill")
                            }
                            .onAppear { selectedTab = 2 }
                    }
                    .accentColor(AppConfig.buttonColor)
                }
            }
            .navigationTitle(dynamicTitle) // ✅ Dynamic Title
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppConfig.buttonColor)
                            .padding(.top, 10)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                if let doctor = doctor {
                    DoctorProfileView(doctor: doctor)
                }
            }
            .navigationBarBackButtonHidden(true)
            .task {
                await fetchDoctorDetails()
            }
        }
    }
    
    private func fetchDoctorDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("Fetching doctor details for ID:", currentUserId)
            
            guard let doctorId = UUID(uuidString: currentUserId) else {
                errorMessage = "Invalid doctor ID"
                isLoading = false
                return
            }
            
            let doctors: [Doctor] = try await supabaseController.client
                .from("Doctor")
                .select()
                .eq("id", value: doctorId)
                .execute()
                .value
            
            if let fetchedDoctor = doctors.first {
                print("Doctor details fetched successfully")
                doctor = fetchedDoctor
            } else {
                print("No doctor found with ID:", doctorId)
                errorMessage = "Doctor not found"
            }
        } catch {
            print("Error fetching doctor details:", error)
            errorMessage = "Failed to load doctor details"
        }
        
        isLoading = false
    }
}

#Preview {
    mainBoard()
}
