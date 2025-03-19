//
//  Dashboard.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import SwiftUI

struct HospitalCard: View {
    let hospital: hospitals
    let viewModel: HospitalViewModel
    
    var body: some View {
        NavigationLink {
            HospitalDetailView(viewModel: viewModel, hospital: hospital)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header with name and status
                HStack {
                    Text(hospital.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    StatusBadge(isActive: hospital.isActive)
                }
                
                // Location info
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hospital.address)
                            .font(.subheadline)
                        Text("\(hospital.city), \(hospital.state) - \(hospital.pincode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Contact info
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                    Text(hospital.contact)
                        .font(.subheadline)
                }
                
                // Email info
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.orange)
                    Text(hospital.email)
                        .font(.subheadline)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isActive ? "Active" : "Inactive")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

struct SuperAdminProfileButton: View {
    @Binding var isShowingProfile: Bool
    
    var body: some View {
        Button(action: { isShowingProfile = true }) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
}

struct SuperAdminProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Super Admin Information") {
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text("Super Admin")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email:")
                        Spacer()
                        Text("admin@example.com")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct AddHospitalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HospitalViewModel
    
    @State private var name = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var pincode = ""
    @State private var contact = ""
    @State private var email = ""
    @State private var isActive = true
    
    // Admin Details
    @State private var adminFullName = ""
    @State private var adminEmail = ""
    @State private var adminPhone = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hospital Details")) {
                    TextField("Name", text: $name)
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Pincode", text: $pincode)
                    TextField("Contact", text: $contact)
                    TextField("Email", text: $email)
                }
                
                Section(header: Text("Admin Details")) {
                    TextField("Full Name", text: $adminFullName)
                    TextField("Email", text: $adminEmail)
                    TextField("Phone Number", text: $adminPhone)
                }
                
                Section(header: Text("Status")) {
                    Toggle("Active", isOn: $isActive)
                        .tint(isActive ? .green : .red)
                }
            }
            .navigationTitle("Add Hospital")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let hospital = hospitals(
                        name: name,
                        address: address,
                        city: city,
                        state: state,
                        pincode: pincode,
                        contact: contact,
                        email: email,
                        isActive: isActive,
                        password: viewModel.generateRandomPassword(),
                        adminName: adminFullName,
                        adminEmail: adminEmail,
                        adminPhone: adminPhone
                    )
                    viewModel.addHospital(hospital)
                    dismiss()
                }
                .disabled(name.isEmpty || address.isEmpty || city.isEmpty || state.isEmpty ||
                         pincode.isEmpty || contact.isEmpty || email.isEmpty ||
                         adminFullName.isEmpty || adminEmail.isEmpty || adminPhone.isEmpty)
            )
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = HospitalViewModel()
    @State private var showingAddHospital = false
    @State private var showingProfile = false
    @State private var searchText = ""
    
    var filteredHospitals: [hospitals] {
        if searchText.isEmpty {
            return viewModel.hospitals
        } else {
            return viewModel.hospitals.filter { hospital in
                hospital.name.localizedCaseInsensitiveContains(searchText) ||
                hospital.city.localizedCaseInsensitiveContains(searchText) ||
                hospital.state.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Section Header
                    HStack {
                        Text("Hospitals")
                            .font(.headline)
                        Spacer()
                        Button(action: { showingAddHospital = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    
                    // Hospital Cards
                    LazyVStack(spacing: 16) {
                        ForEach(filteredHospitals) { hospital in
                            HospitalCard(hospital: hospital, viewModel: viewModel)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .searchable(text: $searchText, prompt: "Search hospitals...")
            .navigationBarItems(trailing: SuperAdminProfileButton(isShowingProfile: $showingProfile))
            .sheet(isPresented: $showingAddHospital) {
                AddHospitalView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingProfile) {
                SuperAdminProfileView()
            }
        }
    }
}

#Preview {
    ContentView()
}

