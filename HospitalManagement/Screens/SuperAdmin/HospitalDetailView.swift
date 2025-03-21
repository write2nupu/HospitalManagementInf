//
//  HospitalDetailView.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import SwiftUI

struct HospitalDetailView: View {
    @ObservedObject var viewModel: HospitalManagementViewModel
    @State var hospital: Hospital
    @State private var isActive: Bool
    @State private var isEditing = false
    @State private var editedHospital: Hospital
    @StateObject private var supabaseController = SupabaseController()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var adminDetails: Admin?
    
    init(viewModel: HospitalManagementViewModel, hospital: Hospital) {
        self.viewModel = viewModel
        _hospital = State(initialValue: hospital)
        _isActive = State(initialValue: hospital.is_active)
        _editedHospital = State(initialValue: hospital)
    }
    
    var body: some View {
        List {
            // Hospital Header
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hospital.name)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.black)
                            Text("License: \(hospital.license_number)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusBadge(isActive: hospital.is_active)
                    }
                    
                    Divider()
                    
                    // Location Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(hospital.address)
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Text("\(hospital.city), \(hospital.state) \(hospital.pincode)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }
            
            // Contact Information
            Section {
                LabeledContent("Phone") {
                    Button(hospital.mobile_number) {
                        guard let url = URL(string: "tel:\(hospital.mobile_number)") else { return }
                        UIApplication.shared.open(url)
                    }
                    .foregroundColor(.mint)
                }
                
                LabeledContent("Email") {
                    Button(hospital.email) {
                        guard let url = URL(string: "mailto:\(hospital.email)") else { return }
                        UIApplication.shared.open(url)
                    }
                    .foregroundColor(.mint)
                }
            } header: {
                Text("Contact Information")
                    .foregroundColor(.black)
            }
            
            // Admin Details
            Section {
                if let admin = adminDetails {
                    Text("Name: \(admin.fullName)")
                    
                    LabeledContent("Phone") {
                        Button(admin.phone_number) {
                            guard let url = URL(string: "tel:\(admin.phone_number)") else { return }
                            UIApplication.shared.open(url)
                        }
                        .foregroundColor(.mint)
                    }
                    
                    LabeledContent("Email") {
                        Button(admin.email) {
                            guard let url = URL(string: "mailto:\(admin.email)") else { return }
                            UIApplication.shared.open(url)
                        }
                        .foregroundColor(.mint)
                    }
                } else {
                    Text("Admin not assigned")
                }
            } header: {
                Text("Admin Details")
                    .foregroundColor(.black)
            }
            
            // Actions
            Section {
                Toggle("Active Status", isOn: Binding(
                    get: { hospital.is_active },
                    set: { newValue in
                        Task {
                            await updateHospitalActive(newValue)
                        }
                    }
                ))
                .tint(.mint)
                
                Button {
                    editedHospital = hospital
                    isEditing = true
                } label: {
                    Text("Edit")
                        .foregroundColor(.mint)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                EditHospitalView(hospital: $editedHospital, isPresented: $isEditing) { updatedHospital in
                    Task {
                        await updateHospital(updatedHospital)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .task {
            if let adminId = hospital.assigned_admin_id {
                adminDetails = await supabaseController.fetchAdminByUUID(adminId: adminId)
            }
        }
    }
    
    private func updateHospitalActive(_ newValue: Bool) async {
        var updatedHospital = hospital
        updatedHospital.is_active = newValue
        await updateHospital(updatedHospital)
    }
    
    private func updateHospital(_ updatedHospital: Hospital) async {
        do {
            try await supabaseController.client
                
                .from("Hospitals")
                .update(updatedHospital)
                .eq("id", value: updatedHospital.id)
                .execute()
            
            hospital = updatedHospital
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
}

struct EditHospitalView: View {
    @Binding var hospital: Hospital
    @Binding var isPresented: Bool
    @StateObject private var supabaseController = SupabaseController()
    @State private var selectedAdmin: Admin?
    @State private var availableAdmins: [Admin] = []
    let onSave: (Hospital) -> Void
    
    var body: some View {
        Form {
            Section("Hospital Information") {
                TextField("Name", text: $hospital.name)
                TextField("License Number", text: $hospital.license_number)
                TextField("Address", text: $hospital.address)
                TextField("City", text: $hospital.city)
                TextField("State", text: $hospital.state)
                TextField("Pincode", text: $hospital.pincode)
            }
            
            Section("Contact Information") {
                TextField("Phone", text: $hospital.mobile_number)
                    .keyboardType(.phonePad)
                TextField("Email", text: $hospital.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            
            Section("Admin Assignment") {
                if !availableAdmins.isEmpty {
                    Picker("Select Admin", selection: $selectedAdmin) {
                        Text("None").tag(Optional<Admin>.none)
                        ForEach(availableAdmins) { admin in
                            Text(admin.fullName).tag(Optional(admin))
                        }
                    }
                } else {
                    Text("No available admins")
                }
            }
        }
        .navigationTitle("Edit Hospital")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                isPresented = false
            },
            trailing: Button("Save") {
                hospital.assigned_admin_id = selectedAdmin?.id
                onSave(hospital)
                isPresented = false
            }
        )
        .task {
            do {
                let admins: [Admin] = try await supabaseController.client
                    .from("Admins")
                    .select()
                    .execute()
                    .value
                availableAdmins = admins
                if let adminId = hospital.assigned_admin_id {
                    selectedAdmin = admins.first { $0.id == adminId }
                }
            } catch {
                print("Error fetching admins: \(error)")
            }
        }
    }
}
