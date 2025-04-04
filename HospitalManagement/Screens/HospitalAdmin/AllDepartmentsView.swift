import SwiftUI

struct AllDepartmentsView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var departments: [Department] = []
    @State private var doctorsByDepartment: [UUID: [Doctor]] = [:]
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var filteredDepartments: [Department] {
        if searchText.isEmpty {
            return departments
        } else {
            return departments.filter { department in
                department.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with total count
                    VStack(alignment: .leading, spacing: 20) {
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
                    }
                    
                    // Departments List
                    VStack(spacing: 16) {
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading departments...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if let error = errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red.opacity(0.3))
                                Text(error)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if departments.isEmpty {
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
                                    DepartmentListCard(department: department, doctorsByDepartment: doctorsByDepartment)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("All Departments")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search department..."
        )
        .task {
            await loadDepartments()
        }
    }
    
    private func loadDepartments() async {
        isLoading = true
        departments = []
        doctorsByDepartment = [:]
        errorMessage = nil
        
        guard let hospitalId = UserDefaults.standard.string(forKey: "hospitalId"),
              let hospitalUUID = UUID(uuidString: hospitalId) else {
            errorMessage = "Could not determine hospital ID"
            isLoading = false
            return
        }
        
        do {
            // Fetch departments
            let fetchedDepartments = try await supabaseController.fetchHospitalDepartments(hospitalId: hospitalUUID)
            
            // For each department, fetch its doctors
            var doctorsMap: [UUID: [Doctor]] = [:]
            for department in fetchedDepartments {
                let doctors = try await supabaseController.getDoctorsByDepartment(departmentId: department.id)
                doctorsMap[department.id] = doctors
            }
            
            await MainActor.run {
                departments = fetchedDepartments
                doctorsByDepartment = doctorsMap
                isLoading = false
            }
        } catch {
            print("Error loading departments: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load departments: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct DepartmentListCard: View {
    let department: Department
    let doctorsByDepartment: [UUID: [Doctor]]
    
    private var doctors: [Doctor] {
        return doctorsByDepartment[department.id] ?? []
    }
    
    private var activeDoctors: [Doctor] {
        return doctors.filter { $0.is_active }
    }
    
    private var inactiveDoctors: [Doctor] {
        return doctors.filter { !$0.is_active }
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
                Text("\(doctors.count) doctors")
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
                Text("\(activeDoctors.count) active")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text("•")
                    .foregroundColor(.secondary)
                Text("\(inactiveDoctors.count) inactive")
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
        }
    }
} 
