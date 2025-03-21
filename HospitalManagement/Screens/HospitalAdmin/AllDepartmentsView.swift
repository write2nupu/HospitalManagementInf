import SwiftUI

struct AllDepartmentsView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var departments: [Department] = []
    @State private var doctors: [Doctor] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with total count
                HStack {
                    Text("Total Departments")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(departments.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)
                }
                .padding(.horizontal)
                
                // Departments List
                LazyVStack(spacing: 16) {
                    ForEach(departments) { department in
                        NavigationLink(destination: DepartmentDetailView(department: department)) {
                            DepartmentCard(
                                department: department,
                                doctorCount: doctors.filter { $0.departmentId == department.id }.count,
                                activeDoctorCount: doctors.filter { $0.departmentId == department.id && $0.isActive }.count
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("All Departments")
        .task {
            if let hospitalId = getCurrentHospitalId() {
                // Fetch departments and doctors concurrently
                async let departmentsTask = supabaseController.fetchHospitalDepartments(hospitalId: hospitalId)
                async let doctorsTask = supabaseController.getDoctorsByHospital(hospitalId: hospitalId)
                
                let (fetchedDepartments, fetchedDoctors) = await (departmentsTask, doctorsTask)
                departments = fetchedDepartments
                doctors = fetchedDoctors
            }
        }
    }
    
    // Helper function to get current hospital ID (implement based on your auth system)
    private func getCurrentHospitalId() -> UUID? {
        // Implement this based on your authentication system
        // For example, get it from UserDefaults or your auth state
        return nil // Replace with actual implementation
    }
}

struct DepartmentCard: View {
    let department: Department
    let doctorCount: Int
    let activeDoctorCount: Int
    
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
                    if let description = department.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Text("₹\(String(format: "%.2f", department.fees))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Active/Inactive Doctors
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.green)
                Text("\(activeDoctorCount) active")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text("•")
                    .foregroundColor(.secondary)
                Text("\(doctorCount - activeDoctorCount) inactive")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        AllDepartmentsView()
    }
} 
