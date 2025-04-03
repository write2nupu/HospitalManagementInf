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
    @AppStorage("hospitalId") private var hospitalIdString: String?
    
    // Emergency and bed request counts
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
            ScrollView {
                VStack(spacing: 24) {
                    // Add Department Card
                    AddDepartmentButton(showAddDepartment: $showAddDepartment)
                    
                    VStack(spacing: 24) {
                        // Requests Section
                        RequestsSection(emergencyRequestsCount: emergencyRequestsCount, leaveRequestsCount: leaveRequestsCount, labReportRequestsCount: labReportRequestsCount)
                        
                        // Departments Section
                        DepartmentsListSection(
                            departments: departments,
                            filteredDepartments: departments,
                            isLoading: isLoadingDepartments,
                            errorMessage: errorMessage,
                            getDoctorCount: getDoctorCount
                        )
                    }
                }
            }
        }
        .background(AppConfig.backgroundColor.ignoresSafeArea())
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
                        .foregroundColor(AppConfig.buttonColor)
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
            await loadEmergencyRequestsCount()
        }
        .refreshable {
            await fetchHospitalName()
            await loadDepartments()
            await loadEmergencyRequestsCount()
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

    private func loadEmergencyRequestsCount() async {
        guard let hospitalIdString = hospitalIdString,
              let hospitalId = UUID(uuidString: hospitalIdString) else {
            return
        }
        
        do {
            let requests = try await supabaseController.fetchEmergencyRequests(hospitalId: hospitalId)
            // Only count pending requests
            emergencyRequestsCount = requests.filter { $0.status.rawValue == "Pending" }.count
        } catch {
            print("Error loading emergency requests count: \(error)")
        }
    }

    // Update the department card to use the fetched doctors
    private func getDoctorCount(for department: Department) -> (total: Int, active: Int) {
        let doctors = doctorsByDepartment[department.id] ?? []
        let activeDoctors = doctors.filter { $0.is_active }
        return (doctors.count, activeDoctors.count)
    }
}

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppConfig.primaryColor)
            .foregroundColor(AppConfig.buttonColor)
            .cornerRadius(10)
        }
    }
}

struct DepartmentsSection: View {
    let departments: [Department]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Departments")
                .font(.headline)
                .foregroundColor(AppConfig.fontColor)
            
            if departments.isEmpty {
                Text("No departments added yet")
                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
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
                .foregroundColor(AppConfig.fontColor)
            
            if doctors.isEmpty {
                Text("No doctors added yet")
                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
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
                    .foregroundColor(AppConfig.fontColor)
                if let description = department.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                }
            }
            Spacer()
            Text("₹\(String(format: "%.2f", department.fees))")
                .foregroundColor(AppConfig.buttonColor)
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(10)
        .shadow(color: AppConfig.shadowColor, radius: 5)
    }
}

struct DoctorRow: View {
    let doctor: Doctor
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(doctor.full_name)
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
                Text(doctor.qualifications)
                    .font(.subheadline)
                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
            }
            Spacer()
            if doctor.is_active {
                Text("Active")
                    .foregroundColor(AppConfig.approvedColor)
            } else {
                Text("Inactive")
                    .foregroundColor(AppConfig.redColor)
            }
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(10)
        .shadow(color: AppConfig.shadowColor, radius: 5)
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
                .foregroundColor(AppConfig.fontColor)
            
            Text("Tap to view all requests")
                .font(.caption)
                .foregroundColor(AppConfig.fontColor.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppConfig.cardColor)
        .cornerRadius(15)
        .shadow(color: AppConfig.shadowColor, radius: 10, x: 0, y: 5)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppConfig.fontColor.opacity(0.7))
            
            TextField("Search departments...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(AppConfig.fontColor)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 8)
        .background(AppConfig.searchBar)
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
                    .fill(AppConfig.primaryColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(AppConfig.buttonColor)
                    )
                Text("Add Department")
                    .font(.headline)
                    .foregroundColor(AppConfig.buttonColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(AppConfig.cardColor)
            .cornerRadius(15)
            .shadow(color: AppConfig.shadowColor, radius: 8)
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
                .foregroundColor(AppConfig.fontColor)
                .padding(.horizontal)
            
            // Emergency Requests Card
            NavigationLink {
                EmergencyRequestsView()
            } label: {
                RequestCard(
                    title: "Emergency",
                    iconName: "cross.case.fill",
                    iconColor: AppConfig.redColor,
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
                    iconColor: AppConfig.pendingColor,
                    count: leaveRequestsCount
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            // Lab Report Requests Card
            NavigationLink {
                LabReportRequestsView()
            } label: {
                RequestCard(
                    title: "Lab Reports",
                    iconName: "flask.fill",
                    iconColor: AppConfig.buttonColor,
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
                    .foregroundColor(AppConfig.fontColor)
                
                Spacer()
                
                if !departments.isEmpty {
                    NavigationLink {
                        AllDepartmentsView()
                    } label: {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(AppConfig.buttonColor)
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
                .foregroundColor(AppConfig.fontColor.opacity(0.7))
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
                .foregroundColor(AppConfig.redColor.opacity(0.3))
            Text(message)
                .font(.headline)
                .foregroundColor(AppConfig.fontColor)
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
                .foregroundColor(AppConfig.buttonColor.opacity(0.3))
            Text("No departments to display")
                .font(.headline)
                .foregroundColor(AppConfig.fontColor)
            Text("Add a department to get started")
                .font(.subheadline)
                .foregroundColor(AppConfig.fontColor.opacity(0.7))
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
                .foregroundColor(AppConfig.buttonColor.opacity(0.3))
            Text("No departments found")
                .font(.headline)
                .foregroundColor(AppConfig.fontColor)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(AppConfig.fontColor.opacity(0.7))
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
                    .foregroundColor(AppConfig.fontColor)
                Spacer()
                Text("\(doctorCount.total) doctors")
                    .font(.caption)
                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
            }
            
            // Department Icon and Info
            HStack(spacing: 8) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 20))
                    .foregroundColor(AppConfig.buttonColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Department ID")
                        .font(.subheadline)
                        .foregroundColor(AppConfig.fontColor)
                    Text("#\(department.id.uuidString.prefix(8))")
                        .font(.caption)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                }
            }
            
            // Active/Inactive Doctors
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(AppConfig.approvedColor)
                Text("\(doctorCount.active) active")
                    .font(.subheadline)
                    .foregroundColor(AppConfig.fontColor)
                Text("•")
                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
                Text("\(doctorCount.total - doctorCount.active) inactive")
                    .font(.subheadline)
                    .foregroundColor(AppConfig.fontColor)
            }
        }
        .padding()
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor, radius: 10, x: 0, y: 5)
        )
    }
}

