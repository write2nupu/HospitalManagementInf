//
//  HomeView.swift
//  HospitalManagement
//
//  Created by Mariyo on 21/03/25.
//

import SwiftUI
struct AdminHomeView: View {

    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var hospitalName: String = "Loading..."
    @State private var hospitalLocation: String = ""
    @State private var showAddDoctor = false
    @State private var showAdminProfile = false
    @State private var showAddDepartment = false
    @State private var searchText = ""
    @State private var departments: [Department] = []
    @State private var isLoadingDepartments = false
    @State private var errorMessage: String?
    @State private var doctorsByDepartment: [UUID: [Doctor]] = [:]
    
    // Emergency and bed request counts (to be implemented with real data later)
    @State private var emergencyRequestsCount = 0
    @State private var leaveRequestsCount = 0
    @State private var labReportRequestsCount = 0
    
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
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Add Department Card
                    AddDepartmentButton(showAddDepartment: $showAddDepartment)
                        .padding(.top, 8)
                    
                    VStack(spacing: 24) {
                        // Requests Section
                        RequestsSection(emergencyRequestsCount: emergencyRequestsCount, leaveRequestsCount: leaveRequestsCount, labReportRequestsCount: labReportRequestsCount)
                        
                        // Departments Section
                        DepartmentsListSection(
                            departments: departments,
                            filteredDepartments: departments, // Use departments directly without filtering
                            isLoading: isLoadingDepartments,
                            errorMessage: errorMessage,
                            getDoctorCount: getDoctorCount
                        )
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle(hospitalName)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdminProfile = true
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.mint)
                }
            }
        }
        .sheet(isPresented: $showAddDepartment) {
            NavigationStack {
                AddDepartmentView()
            }
        }
        .sheet(isPresented: $showAdminProfile) {
            NavigationStack {
                AdminProfileView()
            }
        }
        .task {
            await fetchHospitalName()
            await loadDepartments()
        }
    }
    
    private func fetchHospitalName() async {
        do {
            // Get hospital ID from UserDefaults (stored during login)
            if let hospitalIdString = UserDefaults.standard.string(forKey: "hospitalId"),
               let hospitalId = UUID(uuidString: hospitalIdString) {
                print("Fetching hospital with ID: \(hospitalId)")
                
                // Fetch the specific hospital by ID
                let hospitals: [Hospital] = try await supabaseController.client
                    .from("Hospital")
                    .select("*")
                    .eq("id", value: hospitalId.uuidString)
                    .execute()
                    .value
                
                if let hospital = hospitals.first {
                    print("Successfully fetched hospital for logged-in admin:", hospital)
                    
                    // Get admin name from assigned_admin_id
                    var adminName = "Admin"
                    if let adminId = hospital.assigned_admin_id {
                        let admins: [Admin] = try await supabaseController.client
                            .from("Admin")
                            .select("*")
                            .eq("id", value: adminId.uuidString)
                            .execute()
                            .value
                        
                        if let admin = admins.first {
                            adminName = admin.full_name
                        }
                    }
                    
                    await MainActor.run {
                        hospitalName = hospital.name
                        hospitalLocation = "\(hospital.city), \(hospital.state)"
                    }
                } else {
                    print("No hospital found with ID: \(hospitalId)")
                    await MainActor.run {
                        hospitalName = "Your Hospital"
                        hospitalLocation = "Location not found"
                    }
                }
            } else {
                // Fallback to old method if hospital ID is not in UserDefaults
                if let (hospital, adminName) = try await supabaseController.fetchHospitalAndAdmin() {
                    print("Successfully fetched hospital:", hospital)
                    await MainActor.run {
                        hospitalName = hospital.name
                        hospitalLocation = "\(hospital.city), \(hospital.state)"
                    }
                } else {
                    print("No hospital or admin found")
                    await MainActor.run {
                        hospitalName = "Your Hospital"
                        hospitalLocation = "Location not found"
                    }
                }
            }
        } catch {
            print("Error fetching hospital info:", error.localizedDescription)
            await MainActor.run {
                hospitalName = "Your Hospital"
                hospitalLocation = "Location not found"
            }
        }
    }
    
    private func loadDepartments() async {
        isLoadingDepartments = true
        departments = []
        doctorsByDepartment = [:]
        errorMessage = nil
        
        guard let hospitalId = UserDefaults.standard.string(forKey: "hospitalId"),
              let hospitalUUID = UUID(uuidString: hospitalId) else {
            errorMessage = "Could not determine hospital ID"
            isLoadingDepartments = false
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
                isLoadingDepartments = false
            }
        } catch {
            print("Error loading departments: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load departments: \(error.localizedDescription)"
                isLoadingDepartments = false
            }
        }
    }

    // Update the department card to use the fetched doctors
    private func getDoctorCount(for department: Department) -> (total: Int, active: Int) {
        let doctors = doctorsByDepartment[department.id] ?? []
        let activeDoctors = doctors.filter { $0.is_active }
        return (doctors.count, activeDoctors.count)
    }
}

//struct QuickActionButton: View {
//    let title: String
//    let systemImage: String
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack {
//                Image(systemName: systemImage)
//                    .font(.title2)
//                Text(title)
//                    .font(.caption)
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(Color.mint.opacity(0.1))
//            .foregroundColor(.mint)
//            .cornerRadius(10)
//        }
//    }
//}

struct DepartmentsSection: View {
    let departments: [Department]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Departments")
                .font(.headline)
            
            if departments.isEmpty {
                Text("No departments added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(departments) { department in
                    DepartmentRow(department: department)
                }
            }
        }
    }
}

struct DoctorsSection: View {
    let doctors: [Doctor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Doctors")
                .font(.headline)
            
            if doctors.isEmpty {
                Text("No doctors added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(doctors) { doctor in
                    DoctorRow(doctor: doctor)
                }
            }
               
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct DepartmentRow: View {
    let department: Department
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(department.name)
                    .font(.headline)
                if let description = department.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("₹\(String(format: "%.2f", department.fees))")
                .foregroundColor(.mint)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
    }
}

struct DoctorRow: View {
    let doctor: Doctor
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(doctor.full_name)
                    .font(.headline)
                Text(doctor.qualifications)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if doctor.is_active {
                Text("Active")
                    .foregroundColor(.green)
            } else {
                Text("Inactive")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
        
    }
}

struct RequestCard: View {
    let title: String
    let iconName: String
    let iconColor: Color
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                Spacer()
                Text("\(count)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(iconColor)
                    )
            }
            
            Spacer()
            
            Text("\(title)")
                .font(.title)
                .foregroundColor(.primary)
            
//            Spacer()
            
            Text("Tap to view all requests")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search departments...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    let mockViewModel = HospitalManagementViewModel()
    
    return AdminHomeView()
        .environmentObject(mockViewModel)
}

// MARK: - Component Views
struct AddDepartmentButton: View {
    @Binding var showAddDepartment: Bool
    
    var body: some View {
        Button {
            showAddDepartment = true
        } label: {
            VStack(spacing: 12) {
                Circle()
                    .fill(Color.mint.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.mint)
                    )
                Text("Add Department")
                    .font(.headline)
                    .foregroundColor(.mint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 0)
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

struct RequestsSection: View {
    let emergencyRequestsCount: Int
    let leaveRequestsCount: Int
    let labReportRequestsCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Active Requests")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // Emergency Requests Card
            NavigationLink {
                EmergencyRequestsView()
            } label: {
                RequestCard(
                    title: "Emergency",
                    iconName: "cross.case.fill",
                    iconColor: .red,
                    count: emergencyRequestsCount
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            // Leave Requests Card
            NavigationLink {
                DoctorLeaveView()
            } label: {
                RequestCard(
                    title: "Leave Requests",
                    iconName: "calendar.badge.clock",
                    iconColor: .orange,
                    count: leaveRequestsCount
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            // Lab Report Requests Card
            NavigationLink {
               // LabReportViewAdmin()
            } label: {
                RequestCard(
                    title: "Lab Reports",
                    iconName: "clipboard.text.fill",
                    iconColor: .blue,
                    count: labReportRequestsCount
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
        }
    }
}

struct DepartmentsListSection: View {
    let departments: [Department]
    let filteredDepartments: [Department]
    let isLoading: Bool
    let errorMessage: String?
    let getDoctorCount: (Department) -> (total: Int, active: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack {
                Text("Departments")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !departments.isEmpty {
                    NavigationLink {
                        AllDepartmentsView()
                    } label: {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.mint)
                    }
                }
            }
            .padding(.horizontal)
            
            // Department Cards
            if isLoading {
                LoadingDepartmentsView()
            } else if let error = errorMessage {
                ErrorDepartmentsView(message: error)
            } else if departments.isEmpty {
                EmptyDepartmentsView()
            } else if filteredDepartments.isEmpty {
                NoMatchingDepartmentsView()
            } else {
                DepartmentsHorizontalList(
                    departments: filteredDepartments,
                    getDoctorCount: getDoctorCount
                )
            }
        }
    }
}

struct LoadingDepartmentsView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading departments...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ErrorDepartmentsView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.3))
            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct EmptyDepartmentsView: View {
    var body: some View {
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
    }
}

struct NoMatchingDepartmentsView: View {
    var body: some View {
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
    }
}

struct DepartmentsHorizontalList: View {
    let departments: [Department]
    let getDoctorCount: (Department) -> (total: Int, active: Int)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(departments) { department in
                    NavigationLink {
                        DepartmentDetailView(department: department)
                    } label: {
                        DepartmentCardView(
                            department: department,
                            doctorCount: getDoctorCount(department)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DepartmentCardView: View {
    let department: Department
    let doctorCount: (total: Int, active: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with name and count
            HStack {
                Text(department.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(doctorCount.total) doctors")
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
                Text("\(doctorCount.active) active")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text("•")
                    .foregroundColor(.secondary)
                Text("\(doctorCount.total - doctorCount.active) inactive")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

