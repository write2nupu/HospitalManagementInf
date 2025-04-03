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
    @State private var showStatusChangeAlert = false
    @State private var proposedActiveStatus = false
    @State private var showStatusChangeSuccessAlert = false
    
    init(viewModel: HospitalManagementViewModel, hospital: Hospital) {
        self.viewModel = viewModel
        _hospital = State(initialValue: hospital)
        _isActive = State(initialValue: hospital.is_active)
        _editedHospital = State(initialValue: hospital)
    }
    
    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    var body: some View {
        List {
            // Hospital Header
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Hospital Name", text: $editedHospital.name)
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                                    .foregroundColor(AppConfig.fontColor)
                            } else {
                                Text(hospital.name)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(AppConfig.buttonColor)
                                    .padding(.horizontal)
                            }
                            if isEditing {
                                TextField("License Number", text: $editedHospital.license_number)
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                    .foregroundColor(AppConfig.fontColor)
                            } else {
                                Text("License: \(hospital.license_number)")
                                    .font(.subheadline)
                                    .foregroundColor(AppConfig.buttonColor)
                                    .padding(.horizontal)
                            }
                        }
                        Spacer()
                        StatusBadge(isActive: hospital.is_active)
                    }
                    
                    Divider()
                    
                    // Location Details
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                            TextField("Address", text: $editedHospital.address)
                                .padding(.horizontal)
                                .foregroundColor(.gray)
                            TextField("City", text: $editedHospital.city)
                                .padding(.horizontal)
                                .foregroundColor(.gray)
                            TextField("State", text: $editedHospital.state)
                                .padding(.horizontal)
                                .foregroundColor(.gray)
                            TextField("Pincode", text: $editedHospital.pincode)
                                .padding(.horizontal)
                                .foregroundColor(.gray)
                        } else {
                            Text(hospital.address)
                                .font(.body)
                                .foregroundColor(AppConfig.buttonColor)
                                .padding(.horizontal)
                            
                            Text("\(hospital.city), \(hospital.state) \(hospital.pincode)")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.buttonColor)
                                .padding(.horizontal)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .padding(.vertical, 8)
            }
            
            // Contact Information
            Section {
                if isEditing {
                    LabeledContent("Mobile Number") {
                        TextField("Mobile Number", text: $editedHospital.mobile_number)
                            .padding(.horizontal)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Email") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            TextField("Email", text: $editedHospital.email)
                                .padding(.horizontal)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } else {
                    LabeledContent("Phone") {
                        Button(hospital.mobile_number) {
                            guard let url = URL(string: "tel:\(hospital.mobile_number)") else { return }
                            UIApplication.shared.open(url)
                        }
                        .foregroundColor(AppConfig.buttonColor)
                    }
                    .foregroundColor(AppConfig.fontColor)
                    
                    LabeledContent("Email") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Button(hospital.email) {
                                guard let url = URL(string: "mailto:\(hospital.email)") else { return }
                                UIApplication.shared.open(url)
                            }
                            .foregroundColor(AppConfig.buttonColor)
                            .lineLimit(1)
                        }
                        .padding(.leading, 8)
                    }
                    .foregroundColor(AppConfig.fontColor)
                }
            } header: {
                Text("Contact Information")
                    .foregroundColor(.black)
            }
            
            // Admin Details
            Section {
                if let admin = adminDetails {
                    LabeledContent("Name") {
                        Text(admin.full_name)
                            .foregroundColor(AppConfig.buttonColor)
                    }
                    .foregroundColor(AppConfig.fontColor)
                    
                    LabeledContent("Phone") {
                        Button(admin.phone_number) {
                            guard let url = URL(string: "tel:\(admin.phone_number)") else { return }
                            UIApplication.shared.open(url)
                        }
                        .foregroundColor(AppConfig.buttonColor)
                    }
                    .foregroundColor(AppConfig.fontColor)
                    
                    LabeledContent("Email") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Button(admin.email) {
                                guard let url = URL(string: "mailto:\(admin.email)") else { return }
                                UIApplication.shared.open(url)
                            }
                            .foregroundColor(AppConfig.buttonColor)
                            .lineLimit(1)
                        }
                        .padding(.leading, 8)
                    }
                    .foregroundColor(AppConfig.fontColor)
                } else {
                    Text("Admin not assigned")
                        .foregroundColor(.mint)
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
                        if isEditing {
                            proposedActiveStatus = newValue
                            showStatusChangeAlert = true
                        }
                    }
                ))
                .tint(AppConfig.buttonColor)
                .disabled(!isEditing)
            }
        }
        .navigationTitle("Hospital Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(isEditing ? "Save" : "Edit") {
            if isEditing {
                Task {
                    await updateHospital(editedHospital)
                }
            } else {
                editedHospital = hospital
                isEditing = true
            }
        }
        .foregroundColor(AppConfig.buttonColor))
        .background(AppConfig.backgroundColor)
        .scrollContentBackground(.hidden)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            triggerHaptic(.error)
        }
        .alert("Confirm Status Change", isPresented: $showStatusChangeAlert) {
            Button("Cancel", role: .cancel) {
                // Reset the toggle to its original state
                proposedActiveStatus = hospital.is_active
                triggerHaptic(.warning)
            }
            Button(proposedActiveStatus ? "Activate" : "Deactivate") {
                Task {
                    await updateHospitalActive(proposedActiveStatus)
                    triggerHaptic()
                }
            }
        } message: {
            Text("Are you sure you want to \(proposedActiveStatus ? "activate" : "deactivate") this hospital?")
        }
        .alert("Status Updated", isPresented: $showStatusChangeSuccessAlert) {
            Button("OK") { 
                triggerHaptic()
            }
        } message: {
            Text("Hospital status has been successfully updated")
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
        showStatusChangeSuccessAlert = true
        
        // Refresh the hospitals list in the parent view
        if let parentViewModel = viewModel as? HospitalManagementViewModel {
            parentViewModel.hospitals = await supabaseController.fetchHospitals()
        }
    }
    
    private func updateHospital(_ updatedHospital: Hospital) async {
        do {
            try await supabaseController.updateHospital(updatedHospital)
            hospital = updatedHospital
            isEditing = false
            
            // Refresh the hospitals list in the parent view
            if let parentViewModel = viewModel as? HospitalManagementViewModel {
                parentViewModel.hospitals = await supabaseController.fetchHospitals()
            }
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
    
    // Break down the form sections into separate views
    private var hospitalInfoSection: some View {
        Section("Hospital Information") {
            TextField("Name", text: $hospital.name)
            TextField("License Number", text: $hospital.license_number)
            TextField("Address", text: $hospital.address)
            TextField("City", text: $hospital.city)
            TextField("State", text: $hospital.state)
            TextField("Pincode", text: $hospital.pincode)
        }
    }
    
    private var contactInfoSection: some View {
        Section("Contact Information") {
            TextField("Mobile Number", text: $hospital.mobile_number)
            TextField("Email", text: $hospital.email)
        }
    }
    
    private var adminSection: some View {
        Section("Admin Assignment") {
            if !availableAdmins.isEmpty {
                Picker("Select Admin", selection: $selectedAdmin) {
                    Text("None").tag(Optional<Admin>.none)
                    ForEach(availableAdmins) { admin in
                        Text(admin.full_name).tag(Optional(admin))
                    }
                }
            } else {
                Text("No available admins")
            }
        }
    }
    
    private var statusSection: some View {
        Section("Status") {
            Toggle("Active", isOn: $hospital.is_active)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                hospitalInfoSection
                contactInfoSection
                adminSection
                statusSection
            }
            .background(AppConfig.backgroundColor)
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Hospital")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false }
                    .foregroundColor(AppConfig.buttonColor),
                trailing: Button("Save") {
                    hospital.assigned_admin_id = selectedAdmin?.id
                    onSave(hospital)
                    isPresented = false
                }
                .foregroundColor(AppConfig.buttonColor)
            )
            .task {
                do {
                    let admins: [Admin] = try await supabaseController.client
                        .from("Admin")
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
}
