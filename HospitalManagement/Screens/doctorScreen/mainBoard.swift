import SwiftUICore
import SwiftUI


struct mainBoard: View {
//    var docID: UUID
//    accept id form force update screen and fect user by that ID and stre that doctor in this variable
    
    var doctor: Doctor = Doctor(id: UUID(), full_name: "Anubhav Dubey", experience: 10, qualifications: "MBS", is_active: true, phone_number: "091234857", email_address: "anubhav@mail.com", gender: "male", license_num: "123-123-123")
    @State private var selectedTab: Tab = .dashBoard
    @State private var showProfile = false

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
            return "Hi, Doctor"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                VStack {
                    // **Top Bar with Profile Button & Welcome Message**
                    HStack {
                        VStack(alignment: .leading) {
                            Text(heading) // ✅ Dynamically updates based on selectedTab
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showProfile = true // ✅ Open profile modally
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(AppConfig.buttonColor)
                        }
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    VStack(spacing: 0) {
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

                        // **Custom Tab Bar**
//                        TabBarView(selectedTab: $selectedTab)
                        
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .sheet(isPresented: $showProfile) { // ✅ Modal presentation
                DoctorProfileView(doctor: doctor)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
