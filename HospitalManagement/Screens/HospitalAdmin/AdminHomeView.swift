//
//  HomeView.swift
//  HospitalManagement
//
//  Created by Mariyo on 21/03/25.
//

import SwiftUI

struct AdminHomeView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var doctors: [Doctor] = []
    @State private var departments: [Department] = []
    @State private var showAddDoctor = false
    @State private var showAdminProfile = false
    @State private var showAddDepartment = false
    @State private var searchText = ""
    
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Actions
                    QuickActionsView(
                        showAddDoctor: $showAddDoctor,
                        showAddDepartment: $showAddDepartment
                    )
                    
                    // Departments Section
                    DepartmentsSection(departments: filteredDepartments)
                    
                    // Doctors Section
                    DoctorsSection(doctors: doctors)
                }
                .padding()
            }
            .navigationTitle("Hospital Admin")
            .searchable(text: $searchText, prompt: "Search departments...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdminProfile = true }) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.mint)
                    }
                }
            }
            .sheet(isPresented: $showAddDoctor) {
                AddDoctorView()
            }
            .sheet(isPresented: $showAddDepartment) {
                AddDepartmentView()
            }
            .sheet(isPresented: $showAdminProfile) {
                AdminProfileView()
            }
            .task {
                // Fetch doctors and departments
                if let hospitalId = getCurrentHospitalId() {
                    doctors = await supabaseController.getDoctorsByHospital(hospitalId: hospitalId)
                    departments = await supabaseController.fetchHospitalDepartments(hospitalId: hospitalId)
                }
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

// MARK: - Supporting Views
struct QuickActionsView: View {
    @Binding var showAddDoctor: Bool
    @Binding var showAddDepartment: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            QuickActionButton(
                title: "Add Doctor",
                systemImage: "person.badge.plus",
                action: { showAddDoctor = true }
            )
            
            QuickActionButton(
                title: "Add Department",
                systemImage: "building.2.fill",
                action: { showAddDepartment = true }
            )
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
                Text(doctor.fullName)
                    .font(.headline)
                Text(doctor.qualifications)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if doctor.isActive {
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
