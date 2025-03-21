import SwiftUI

struct DepartmentListView: View {
    let departments: [Department]
    @State private var searchText = ""  // 🔹 State variable for search

    // Adaptive Grid Layout with 2 Columns
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    // 🔹 Filtered Departments based on Search Query
    var filteredDepartments: [Department] {
        if searchText.isEmpty {
            return departments
        } else {
            return departments.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            // 🔍 Search Bar
            TextField("Search departments...", text: $searchText)
                .padding(10)
                .background(Color.mint.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(filteredDepartments, id: \.name) { department in
                        NavigationLink(destination: DoctorListView(doctors: department.doctors)) {
                            departmentCard(department: department)
                        }
                    }
                }
                .padding()

                // 🔹 Show "No results" if search has no matches
                if filteredDepartments.isEmpty {
                    Text("No departments found")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Select Department")
        .background(Color.mint.opacity(0.05)) // Soft mint background
    }

    // MARK: - Department Card UI
    private func departmentCard(department: Department) -> some View {
        VStack(alignment: .leading, spacing: 6) {
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

