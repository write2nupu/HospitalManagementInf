import SwiftUI

struct HospitalListView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var hospitals: [Hospital] = []
    @State private var departmentsByHospital: [UUID: [Department]] = [:]
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedHospitalId") private var selectedHospitalId: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 15) {
                        ForEach(hospitals) { hospital in
                            Button {
                                // Set selected hospital and go back to home screen
                                selectedHospitalId = hospital.id.uuidString
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "building.fill")
                                            .foregroundColor(.mint)
                                            .font(.system(size: 24))
                                        
                                        Text(hospital.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    
                                    Text("\(hospital.city), \(hospital.state)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    Text(hospital.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .mint.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
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
}


