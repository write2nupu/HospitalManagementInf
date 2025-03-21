import SwiftUI

class HospitalManagementTestViewModel: ObservableObject {
    @Published var showUserProfile = false
}

// MARK: - Patient Dashboard View
struct PatientDashboard: View {
    private var viewModel: HospitalManagementViewModel = .init()
    @State private var patient: Patient
    @State private var showprofile = false
    
    init(patient: Patient) {
        _patient = State(initialValue: patient)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Top Section
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hi, \(patient.fullName)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                        Text("Welcome to your dashboard! Let's take care of your health.")
                            .font(.body)
                            .foregroundColor(.mint.opacity(0.8))
                    }
                    Spacer()
                    Button(action: {
//                        viewModel.showUserProfile = true  // ✅ No more error
                        showprofile = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.mint)
                    }
                    .sheet(isPresented: $showprofile) {
                        ProfileView(patient: $patient)
                    } 
                }
                .padding()
                
                // Quick Actions Section
                Text("Quick Action")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                    .padding(.horizontal)
                    .padding(.top)
                
                NavigationLink(destination: HospitalListView()) {
                    VStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.mint)
                        Text("Find Hospital")
                            .font(.headline)
                            .foregroundColor(.mint)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color.mint.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
