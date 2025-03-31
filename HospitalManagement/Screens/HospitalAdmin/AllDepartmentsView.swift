import SwiftUI

struct AllDepartmentsView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @State private var searchText = ""
    
    var filteredDepartments: [Department] {
        if searchText.isEmpty {
            return viewModel.departments
        } else {
            return viewModel.departments.filter { department in
                department.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with total count
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Total Departments")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.departments.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                    }
                    .padding(.horizontal)
                }
                
                // Departments List
                VStack(spacing: 16) {
                    if viewModel.departments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .font(.system(size: 40))
                                .foregroundColor(.mint.opacity(0.3))
                            Text("No departments to display")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Add a department to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if filteredDepartments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.mint.opacity(0.3))
                            Text("No departments found")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredDepartments) { department in
                            NavigationLink {
                                DepartmentDetailView(department: department)
                            } label: {
                                DepartmentListCard(department: department)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("All Departments")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search department..."
        )
    }
}

struct DepartmentListCard: View {
    let department: Department
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
    private var doctorCount: Int {
        viewModel.getDoctorsByHospital(hospitalId: department.hospital_id ?? UUID()).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and count
            HStack {
                Text(department.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(doctorCount) doctors")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Department Icon and Info
            HStack(spacing: 8) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 20))
                    .foregroundColor(.mint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Department ID")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("#\(department.id.uuidString.prefix(8))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Active/Inactive Doctors
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.green)
                Text("\(viewModel.getDoctorsByHospital(hospitalId: department.hospital_id ?? UUID()).filter { $0.is_active }.count) active")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text("•")
                    .foregroundColor(.secondary)
                Text("\(viewModel.getDoctorsByHospital(hospitalId: department.hospital_id ?? UUID()).filter { !$0.is_active }.count) inactive")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Preview
struct AllDepartmentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AllDepartmentsView()
                .environmentObject(HospitalManagementViewModel())
        }
    }
} 
