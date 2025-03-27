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
    @State private var showAddDoctor = false
    @State private var showAdminProfile = false
    @State private var showAddDepartment = false
    @State private var searchText = ""
    
    // Add dummy counters (replace with actual data later)
    private let emergencyRequestsCount = 5
    private let bedRequestsCount = 3
    
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
        NavigationStack {
            ScrollView {
                
                // Add Department Card
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
                
                
                VStack(spacing: 24) {
                    // Requests Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Active Requests")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
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
                            }
                            
                            // Bed Requests Card
                            NavigationLink {
                                BedRequestsView()
                            } label: {
                                RequestCard(
                                    title: "Bed",
                                    iconName: "bed.double.fill",
                                    iconColor: .blue,
                                    count: bedRequestsCount
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    
                    // Departments Section
                    VStack(alignment: .leading, spacing: 20) {
                        // Section Header
                        HStack {
                            Text("Departments")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if !viewModel.departments.isEmpty {
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
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(filteredDepartments) { department in
                                        NavigationLink {
                                            DepartmentDetailView(department: department)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                // Header with name and count
                                                HStack {
                                                    Text(department.name)
                                                        .font(.title3)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    Text("\(viewModel.getDoctorsByHospital(hospitalId: department.hospital_id ?? UUID()).count) doctors")
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
                                            .frame(width: 300, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(Color(.systemBackground))
                                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(hospitalName)
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
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search departments..."
            )
            .sheet(isPresented: $showAddDepartment) {
                NavigationStack {
                    AddDepartmentView()
                }
            }
            .sheet(isPresented: $showAdminProfile) {
                AdminProfileView()
            }
        }
        .onAppear {
            Task {
                await fetchHospitalName()
            }
        }
    }
    
    private func fetchHospitalName() async {
        do {
            if let (hospital, adminName) = try await supabaseController.fetchHospitalAndAdmin() {
                print("Successfully fetched hospital:", hospital)
                await MainActor.run {
                    hospitalName = "Hi \(adminName)"
                }
            } else {
                print("No hospital or admin found")
                await MainActor.run {
                    hospitalName = "No Hospital or Admin Found"
                }
            }
        } catch {
            print("Error fetching hospital and admin:", error.localizedDescription)
            await MainActor.run {
                hospitalName = "Error Loading Details"
            }
        }
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
            .background(Color.mint.opacity(0.1))
            .foregroundColor(.mint)
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
        .background(Color.white)
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
        .background(Color.white)
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
        .frame(width: 180,height: 140 ,alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    let mockViewModel = HospitalManagementViewModel()
    
    return AdminHomeView()
        .environmentObject(mockViewModel)
}

