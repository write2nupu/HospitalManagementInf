import SwiftUI

struct AppointmentsTabView: View {
    @StateObject private var coordinator = NavigationCoordinator.shared
    @State private var shouldRefresh = false
    
    var body: some View {
        VStack {
            AppointmentListView()
        }
        .navigationTitle("Appointments")
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationView {
        AppointmentsTabView()
    }
}
