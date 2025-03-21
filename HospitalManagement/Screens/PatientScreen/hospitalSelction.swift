import SwiftUI

struct HospitalListView: View {
    @State private var searchText = ""
    
    var filteredHospitals: [Hospital] {
        if searchText.isEmpty {
            return hospitals
        } else {
            return hospitals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                TextField("Search hospitals...", text: $searchText)
                    .padding(10)
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(filteredHospitals, id: \.name) { hospital in
                            NavigationLink(destination: DepartmentListView(departments: hospital.departments)) {
                                hospitalCard(hospital: hospital)
                            }
                        }
                        
                        // Show "No results" if search has no matches
                        if filteredHospitals.isEmpty {
                            Text("No hospitals found")
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Hospital")
            .background(Color.mint.opacity(0.05))
        }
    }

    // MARK: - Hospital Card UI
    private func hospitalCard(hospital: Hospital) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hospital.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.mint)
            
            Text(hospital.location)
                .font(.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// ✅ Preview
struct HospitalListView_Previews: PreviewProvider {
    static var previews: some View {
        HospitalListView()
    }
}
