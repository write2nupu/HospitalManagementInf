import SwiftUI

struct DepartmentListView: View {
    let departments: [Department]

    // Adaptive Grid Layout with 2 Columns
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(departments, id: \.name) { department in
                    NavigationLink(destination: DoctorListView(doctors: department.doctors)) {
                        departmentCard(department: department)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select Department")
        .background(Color.mint.opacity(0.05)) // Soft mint background
    }

    // MARK: - Department Card UI
    private func departmentCard(department: Department) -> some View {
        VStack(alignment: .leading, spacing: 6) {  // 🔹 Consistent alignment
            Text(department.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.mint)
            
            Divider() // 🔹 Adds a clear separation

            Text("Doctors Available:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("\(department.doctors.count)")
                .font(.headline)
                .foregroundColor(.mint)
        }
        .frame(maxWidth: .infinity, minHeight: 100) // 🔹 Consistent card size
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

