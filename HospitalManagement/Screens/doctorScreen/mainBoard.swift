import SwiftUICore
import SwiftUI

struct mainBoard: View {
    @StateObject private var supabaseController = SupabaseController()
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var selectedTab: Tab = .dashBoard
    @State private var showProfile = false
    @State private var doctor: Doctor?
    @State private var isLoading = true
    @State private var errorMessage: String?

    enum Tab {
        case appointments, patients, dashBoard
    }
    
    var heading: String {
        switch selectedTab {
        case .appointments:
            return "Appointments"
        case .patients:
            return "Patients"
        case .dashBoard:
            return "Hi, \(doctor?.full_name.components(separatedBy: " ").first ?? "Doctor")"
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
                } else if let doctor = doctor {
                    VStack {
                        // **Content Area (Switches Based on Selected Tab)**
                        Group {
                            if selectedTab == .appointments {
                                AppointmentView()
                            } else if selectedTab == .patients {
                                patientView()
                            } else if selectedTab == .dashBoard {
                                DoctorDashBoard()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        TabBarView(selectedTab: $selectedTab)
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .navigationTitle(heading) // ✅ Title now appears properly
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
            
            // Fetch doctor details from Supabase
            let doctors: [Doctor] = try await supabaseController.client.database
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
