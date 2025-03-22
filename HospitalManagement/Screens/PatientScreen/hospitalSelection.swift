import SwiftUI

struct HospitalListView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var hospitals: [Hospital] = []
    @State private var departmentsByHospital: [UUID: [Department]] = [:]
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 15) {
                        ForEach(hospitals) { hospital in
                            NavigationLink {
                                DepartmentListView()
                                    .onAppear {
                                        UserDefaults.standard.set(hospital.id.uuidString, forKey: "selectedHospitalId")
                                    }
                            } label: {
                                hospitalCard(hospital: hospital)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Hospital")
            .background(Color.mint.opacity(0.05)) // Soft mint background
            .task {
                await loadHospitals()
            }
        }
    }
    
    private func loadHospitals() async {
        isLoading = true
        let fetchedHospitals = await supabaseController.fetchHospitals()
        hospitals = fetchedHospitals.filter { $0.is_active }
        isLoading = false
    }

    // MARK: - Hospital Card UI
    private func hospitalCard(hospital: Hospital) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hospital.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.mint)
            
            Text("\(hospital.city), \(hospital.state)")
                .font(.body)
                .foregroundColor(.gray)
            
            Text(hospital.address)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 80) // Consistent size for all cards
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}


