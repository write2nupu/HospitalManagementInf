import SwiftUI

struct HospitalListView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(hospitals, id: \.name) { hospital in
                        NavigationLink(destination: DepartmentListView(departments: hospital.departments)) {
                            hospitalCard(hospital: hospital)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Hospital")
            .background(Color.mint.opacity(0.05)) // Soft mint background
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
        .frame(maxWidth: .infinity, minHeight: 80) // Consistent size for all cards
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
