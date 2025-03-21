import SwiftUI

struct DepartmentListView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var departments: [Department] = []
    @State private var doctorsByDepartment: [UUID: [Doctor]] = [:]
    @AppStorage("selectedHospitalId") private var selectedHospitalId: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Adaptive Grid Layout with 2 Columns
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if departments.isEmpty {
                Text("No departments available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(departments) { department in
                        NavigationLink(destination: DoctorListView(doctors: doctorsByDepartment[department.id] ?? [])) {
                            departmentCard(department: department)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Select Department")
        .background(Color.mint.opacity(0.05)) // Soft mint background
        .task {
            await loadDepartmentsAndDoctors()
        }
        .refreshable {
            await loadDepartmentsAndDoctors()
        }
    }

    private func loadDepartmentsAndDoctors() async {
        isLoading = true
        errorMessage = nil
        
        guard let hospitalId = getCurrentHospitalId() else {
            errorMessage = "Please select a hospital first"
            isLoading = false
            return
        }
        
        do {
            // Fetch departments and doctors concurrently
            let departmentsTask = await supabaseController.fetchHospitalDepartments(hospitalId: hospitalId)
            let doctorsTask = await supabaseController.getDoctorsByHospital(hospitalId: hospitalId)
            
            // Wait for both to complete and handle potential errors
            let fetchedDepartments = try await departmentsTask
            let allDoctors = try await doctorsTask
            
            // Update departments
            departments = fetchedDepartments
            
            // Group active doctors by department
            doctorsByDepartment = Dictionary(
                grouping: allDoctors.filter { $0.isActive },
                by: { $0.departmentId ?? UUID() }
            )
            
        } catch {
            errorMessage = "Failed to load departments: \(error.localizedDescription)"
        }
        
        isLoading = false
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
            
            Text("\(doctorsByDepartment[department.id]?.count ?? 0)")
                .font(.headline)
                .foregroundColor(.mint)
            
            if let description = department.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text("Consultation Fee: ₹\(String(format: "%.2f", department.fees))")
                .font(.caption)
                .foregroundColor(.mint)
        }
        .frame(maxWidth: .infinity, minHeight: 100) // 🔹 Consistent card size
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private func getCurrentHospitalId() -> UUID? {
        UUID(uuidString: selectedHospitalId)
    }
}

