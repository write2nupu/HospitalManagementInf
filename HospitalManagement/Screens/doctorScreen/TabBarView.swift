import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: mainBoard.Tab

    enum Tab {
        case appointments, patients, dashBoard
    }
    
    var appointmentsCount = 6  // Dummy Data
    var patientsCount = 3       // Dummy Data

    var body: some View {
        VStack {
            Divider() // Top separator

            HStack {
                // **Patients Tab**
                Button(action: {
                    selectedTab = .dashBoard
                }) {
                    VStack {
                        Image(systemName: "clipboard.fill")
                            .resizable()
                            .frame(width: 34, height: 24)
                            .foregroundColor(selectedTab == .dashBoard ? AppConfig.buttonColor : .gray)

                        Text("DashBoard") // Dummy data usage
                            .font(.footnote)
                            .foregroundColor(selectedTab == .dashBoard ? AppConfig.buttonColor : .gray)
                    }
                }
                
                Spacer()
                
                // **Appointments Tab**
                Button(action: {
                    selectedTab = .appointments
                }) {
                    VStack {
                        Image(systemName: "calendar.badge.clock")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == .appointments ? AppConfig.buttonColor : .gray)

                        Text("Appointments") // Dummy data usage
                            .font(.footnote)
                            .foregroundColor(selectedTab == .appointments ? AppConfig.buttonColor : .gray)
                    }
                }
                
                Spacer()

                // **Patients Tab**
                Button(action: {
                    selectedTab = .patients
                }) {
                    VStack {
                        Image(systemName: "person.2.fill")
                            .resizable()
                            .frame(width: 34, height: 24)
                            .foregroundColor(selectedTab == .patients ? AppConfig.buttonColor : .gray)

                        Text("Patients") // Dummy data usage
                            .font(.footnote)
                            .foregroundColor(selectedTab == .patients ? AppConfig.buttonColor : .gray)
                    }
                }
                
                
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 10)
            .background(Color.white)
//            .padding(.bottom, 10)
        }
    }
}

// **Preview**
#Preview {
    TabBarView(selectedTab: .constant(.appointments))
}
