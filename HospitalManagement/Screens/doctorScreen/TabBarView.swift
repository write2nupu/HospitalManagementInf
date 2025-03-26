import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: mainBoard.Tab

    
    
    var body: some View {
        VStack {
            Divider() // Top separator
            
            HStack {
                Spacer() // Ensures equal spacing

                // **Home Tab**
                Button(action: {
                    selectedTab = .dashBoard
                }) {
                    VStack(spacing: 4) { // Spacing between icon and text
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == .dashBoard ? AppConfig.buttonColor : .gray)

                        Text("Home")
                            .font(.footnote)
                            .foregroundColor(selectedTab == .dashBoard ? AppConfig.buttonColor : .gray)
                    }
                }

                Spacer() 
                Spacer()

                // **Appointments Tab**
                Button(action: {
                    selectedTab = .appointments
                }) {
                    VStack(spacing: 4) { // Spacing between icon and text
                        Image(systemName: "calendar.badge.clock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == .appointments ? AppConfig.buttonColor : .gray)

                        Text("Appointments")
                            .font(.footnote)
                            .foregroundColor(selectedTab == .appointments ? AppConfig.buttonColor : .gray)
                    }
                }

                Spacer() // Ensures equal spacing
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }
}

// **Preview**
#Preview {
    TabBarView(selectedTab: .constant(.appointments))
}
