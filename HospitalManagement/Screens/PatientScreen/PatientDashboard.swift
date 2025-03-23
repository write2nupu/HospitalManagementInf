import SwiftUI

class HospitalManagementTestViewModel: ObservableObject {
    @Published var showUserProfile = false
}

// MARK: - Patient Dashboard View
struct PatientDashboard: View {
    private var viewModel: HospitalManagementViewModel = .init()
    @State private var patient: Patient
    @State private var showProfile = false
    
    init(patient: Patient) {
        _patient = State(initialValue: patient)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Top Section
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hi, \(patient.fullName)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Welcome! Let's take care of your health.")
                            .font(.body)
                            .foregroundColor(.black.opacity(0.8))
                    }
                    Spacer()
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                    }
                    .sheet(isPresented: $showProfile) {
                        if let selectedDetails = viewModel.patientDetails.first(where: { $0.id == patient.detailId }) {
                            ProfileView(patient: $patient, patientDetails: selectedDetails)
                        } else {
                            Text("No details found for this patient.")
                            
                        }
                    }                }
                .padding(.horizontal)
                
                // Quick Actions Section
                Text("Quick Action")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                
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
            .padding(.vertical, 20)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
}
