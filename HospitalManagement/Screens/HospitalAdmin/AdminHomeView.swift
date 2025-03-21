//
//  HomeView.swift
//  HospitalManagement
//
//  Created by Mariyo on 21/03/25.
//

import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @State private var showAddDoctor = false
    @State private var showAdminProfile = false
    @State private var showAddDepartment = false
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                    
                    // Departments Section
                    VStack(alignment: .leading, spacing: 20) {
                        // Section Header
                        HStack {
                            Text("Departments")
                                .font(.title2)
                                .fontWeight(.bold)
                            
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
                                                    Text("\(viewModel.getDoctorsByHospital(hospitalId: department.hospitalId ?? UUID()).count) doctors")
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
                                                    Text("\(viewModel.getDoctorsByHospital(hospitalId: department.hospitalId ?? UUID()).filter { $0.isActive }.count) active")
                                                        .font(.subheadline)
                                                        .foregroundColor(.primary)
                                                    Text("•")
                                                        .foregroundColor(.secondary)
                                                    Text("\(viewModel.getDoctorsByHospital(hospitalId: department.hospitalId ?? UUID()).filter { !$0.isActive }.count) inactive")
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
            .navigationTitle("Hospital Staff")
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
    }
}

// MARK: - Preview
struct AdminHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AdminHomeView()
            .environmentObject(HospitalManagementViewModel())
    }
}
