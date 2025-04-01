import SwiftUI

struct EmergencyRequestsView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red.opacity(0.3))
                    
                    Text("No Emergency Requests")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("When emergency requests are received, they will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 60)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Emergency Requests")
    }
}

#Preview {
    EmergencyRequestsView()
        .environmentObject(HospitalManagementViewModel())
} 