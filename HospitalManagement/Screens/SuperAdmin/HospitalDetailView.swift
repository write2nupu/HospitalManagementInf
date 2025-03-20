//
//  HospitalDetailView.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import SwiftUI

struct HospitalDetailView: View {
    @ObservedObject var viewModel: HospitalViewModel
    @State var hospital: hospital
    @State private var isActive: Bool
    @State private var isEditing = false
    @State private var editedHospital: hospital
    
    init(viewModel: HospitalViewModel, hospital: hospital) {
        self.viewModel = viewModel
        _hospital = State(initialValue: hospital)
        _isActive = State(initialValue: hospital.isActive)
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
                            Text("License: \(hospital.licenseNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusBadge(isActive: hospital.isActive)
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
                    Button(hospital.contact) {
                        guard let url = URL(string: "tel:\(hospital.contact)") else { return }
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
                LabeledContent("Name", value: hospital.adminName)
                
                LabeledContent("Phone") {
                    Button(hospital.adminPhone) {
                        guard let url = URL(string: "tel:\(hospital.adminPhone)") else { return }
                        UIApplication.shared.open(url)
                    }
                    .foregroundColor(.mint)
                }
                
                LabeledContent("Email") {
                    Button(hospital.adminEmail) {
                        guard let url = URL(string: "mailto:\(hospital.adminEmail)") else { return }
                        UIApplication.shared.open(url)
                    }
                    .foregroundColor(.mint)
                }
            } header: {
                Text("Administrator")
                    .foregroundColor(.black)
            }
            
            // Status
            Section {
                Toggle("Active Status", isOn: $isActive)
                    .tint(.mint)
                    .onChange(of: isActive) { oldValue, newValue in
                        updateHospitalActive(newValue)
                    }
            } header: {
                Text("Status")
                    .foregroundColor(.black)
            } footer: {
                Text("When inactive, the hospital will not be visible to patients")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Login Credentials
            Section {
                LabeledContent("Username", value: hospital.email)
                LabeledContent("Password") {
                    HStack {
                        Text(hospital.password)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.mint)
                    }
                }
                .textSelection(.enabled)
            } header: {
                Text("Login Credentials")
                    .foregroundColor(.black)
            } footer: {
                Text("Tap password to copy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(hospital.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isEditing = true }) {
                    Text("Edit")
                        .foregroundColor(.mint)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                EditHospitalView(hospital: $editedHospital, isPresented: $isEditing) { updatedHospital in
                    hospital = updatedHospital
                    viewModel.updateHospital(updatedHospital)
                }
            }
        }
    }
    
    private func updateHospitalActive(_ newValue: Bool) {
        var updatedHospital = hospital
        updatedHospital.isActive = newValue
        viewModel.updateHospital(updatedHospital)
        hospital = updatedHospital
    }
}

struct EditHospitalView: View {
    @Binding var hospital: hospital
    @Binding var isPresented: Bool
    let onSave: (hospital) -> Void
    
    var body: some View {
        Form {
            Section("Hospital Information") {
                TextField("Name", text: $hospital.name)
                TextField("License Number", text: $hospital.licenseNumber)
                TextField("Address", text: $hospital.address)
                TextField("City", text: $hospital.city)
                TextField("State", text: $hospital.state)
                TextField("Pincode", text: $hospital.pincode)
            }
            
            Section("Contact Information") {
                TextField("Phone", text: $hospital.contact)
                    .keyboardType(.phonePad)
                TextField("Email", text: $hospital.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            
            Section("Admin Details") {
                TextField("Name", text: $hospital.adminName)
                TextField("Email", text: $hospital.adminEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Phone", text: $hospital.adminPhone)
                    .keyboardType(.phonePad)
            }
        }
        .navigationTitle("Edit Hospital")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.mint)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(hospital)
                    isPresented = false
                }
                .foregroundColor(.mint)
            }
        }
    }
}
