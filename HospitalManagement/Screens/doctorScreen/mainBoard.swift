import SwiftUI

struct mainBoard: View {
    @StateObject private var supabaseController = SupabaseController()
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var showProfile = false
    @State private var doctor: Doctor?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Track selected tab
    @State private var selectedTab: Int = 0
    
    var tabTitles = ["Dashboard", "Appointments", "Patients"]
    
    // Track scroll position for dynamic title
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    
    
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
                } else {
                    TabView(selection: $selectedTab) {
                        DoctorDashBoard(doctor: doctor)
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                scrollOffset = value
                            }
                            .tag(0)
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }

                        AppointmentView()
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                scrollOffset = value
                            }
                            .tag(1)
                            .tabItem {
                                Label("Appointments", systemImage: "calendar")
                            }

                        PatientView()
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                scrollOffset = value
                            }
                            .tag(2)
                            .tabItem {
                                Label("Patients", systemImage: "person.fill")
                            }
                    }
                    .accentColor(AppConfig.buttonColor)
                    .navigationTitle(dynamicTitle)
//                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showProfile = true
                            }) {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(AppConfig.buttonColor)
                            }
                        }
                    }
                }
            }
//            .background(AppConfig.backgroundColor)
//            .navigationBarTitleDisplayMode(.automatic)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(AppConfig.backgroundColor, for: .navigationBar)
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
    
    private var dynamicTitle: String {
        if selectedTab == 0 {
            return "Hi, \(doctor?.full_name.components(separatedBy: " ").first ?? "Doctor")"
        } else {
            return tabTitles[selectedTab]
        }
    }
    
    private var selectedTabTitle: String {
        switch selectedTab {
        case 0:
            return "Dashboard"
        case 1:
            return "Appointments"
        case 2:
            return "Patients"
        default:
            return ""
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

// Scroll offset preference key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    mainBoard()
}
