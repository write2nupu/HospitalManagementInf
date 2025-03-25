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
            VStack(alignment: .leading) {
                
                // MARK: - Subtitle Section
                Text("Let's take care of your health.")
                    .font(.body)
                    .foregroundColor(AppConfig.fontColor)
                    .padding(.horizontal)
                
                // MARK: - Quick Actions Section
                Text("Quick Action")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.fontColor)
                    .padding(.horizontal)
                    .padding(.top)
                
                NavigationLink(destination: HospitalListView()) {
                    VStack(spacing: 12) {
                        Image(systemName: "building.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppConfig.buttonColor)
                        
                        Text("Select Hospital")
                            .font(.title3)
                            .foregroundColor(AppConfig.fontColor)
                            .fontWeight(.regular)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                    .navigationBarBackButtonHidden(true)
            }
            
            // MARK: - Navigation Title with Patient's Name
            .navigationTitle(Text("Hi, \(patient.fullname)"))
            .toolbar {
                // Profile Picture in the Top Right
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppConfig.buttonColor)
                    }
                    .sheet(isPresented: $showProfile) {
                        ProfileView(patient: $patient)
                    }
                }
            }
            .background(AppConfig.backgroundColor)
            
        }
    }
}

// MARK: - Preview
#Preview {
    PatientDashboard(patient: Patient(
        id: UUID(),
        fullName: "Tarun",
        gender: "male",
        dateOfBirth: Date(),
        contactNo: "1234567898",
        email: "tarun@gmail.com"
    ))
}
