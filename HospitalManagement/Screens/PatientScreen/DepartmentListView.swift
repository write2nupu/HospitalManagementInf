import SwiftUI

struct DepartmentListView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var departments: [Department] = []
    @State private var doctorsByDepartment: [UUID: [Doctor]] = [:]
    @AppStorage("selectedHospitalId") private var selectedHospitalId: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    // Filtered departments based on search
    private var filteredDepartments: [Department] {
        if searchText.isEmpty {
            return departments
        } else {
            return departments.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) ||
                ($0.description?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }

    // Update the grid layout to use single column
    let columns = [
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                TextField("Search departments", text: $searchText)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppConfig.searchBar)
            )
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if filteredDepartments.isEmpty {
                    VStack(spacing: 15) {
                        if searchText.isEmpty {
                            Image(systemName: "building.2.crop.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No departments available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No departments found for '\(searchText)'")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    // Results Counter
                    if !searchText.isEmpty {
                        HStack {
                            Text("Found \(filteredDepartments.count) department(s)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(filteredDepartments) { department in
                            NavigationLink(destination: DoctorListView(doctors: doctorsByDepartment[department.id] ?? [])) {
                                departmentCard(department: department)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Select Department")
        .background(AppConfig.backgroundColor) // Soft mint background
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
            // Fetch departments first
            let fetchedDepartments = try await supabaseController.fetchHospitalDepartments(hospitalId: hospitalId)
            departments = fetchedDepartments
                 
            // Fetch doctors for each department
            var doctorsByDept: [UUID: [Doctor]] = [:]
            for department in fetchedDepartments {
                let doctors = try await supabaseController.getDoctorsByDepartment(departmentId: department.id)
                doctorsByDept[department.id] = doctors.filter { $0.is_active }
            }
                 
            // Update doctors by department
            doctorsByDepartment = doctorsByDept
                 
        } catch {
            errorMessage = "Failed to load departments: \(error.localizedDescription)"
        }
             
        isLoading = false
    }
    
    // MARK: - Department Card UI
    private func departmentCard(department: Department) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(department.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppConfig.buttonColor)
                    .font(.caption)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Doctors")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(doctorsByDepartment[department.id]?.count ?? 0)")
                        .font(.headline)
                        .foregroundColor(AppConfig.buttonColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fee")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("₹\(String(format: "%.2f", department.fees))")
                        .font(.headline)
                        .foregroundColor(AppConfig.buttonColor)
                }
                
                Spacer()
            }
            
            if let description = department.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppConfig.buttonColor)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.cardColor)
                .shadow(color: .mint.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    private func getCurrentHospitalId() -> UUID? {
        UUID(uuidString: selectedHospitalId)
    }
}

