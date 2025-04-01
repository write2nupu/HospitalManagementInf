import SwiftUI

struct AppointmentsTabView: View {
    @StateObject private var coordinator = NavigationCoordinator.shared
    @State private var shouldRefresh = false
    
    var body: some View {
        NavigationView {
            VStack {
                AppointmentListView()
            }
            .navigationTitle("Appointments")
        }
    }
}

#Preview {
    NavigationView {
        AppointmentsTabView()
    }
}
