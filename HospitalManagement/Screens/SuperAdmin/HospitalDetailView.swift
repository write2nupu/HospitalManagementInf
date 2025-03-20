//
//  HospitalDetailView.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import SwiftUI

struct HospitalDetailView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @State private var hospital: Hospital
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss
    
    init(hospital: Hospital) {
        _hospital = State(initialValue: hospital)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Hospital Information")) {
                if isEditing {
                    TextField("Name", text: $hospital.name)
                    TextField("Address", text: $hospital.address)
                    TextField("City", text: $hospital.city)
                    TextField("State", text: $hospital.state)
                    TextField("Pincode", text: $hospital.pincode)
                } else {
                    LabeledContent("Name", value: hospital.name)
                    LabeledContent("Address", value: hospital.address)
                    LabeledContent("City", value: hospital.city)
                    LabeledContent("State", value: hospital.state)
                    LabeledContent("Pincode", value: hospital.pincode)
                }
            }
            
            Section(header: Text("Contact Information")) {
                if isEditing {
                    TextField("Mobile Number", text: $hospital.mobileNumber)
                    TextField("Email", text: $hospital.email)
                    TextField("License Number", text: $hospital.licenseNumber)
                } else {
                    LabeledContent("Mobile", value: hospital.mobileNumber)
                    LabeledContent("Email", value: hospital.email)
                    LabeledContent("License", value: hospital.licenseNumber)
                }
            }
            
            if let adminId = hospital.assignedAdminId {
                Section(header: Text("Assigned Admin")) {
                    if let admin = viewModel.admins.first(where: { $0.id == adminId }) {
                        LabeledContent("Name", value: admin.fullName)
                        LabeledContent("Email", value: admin.email)
                        LabeledContent("Phone", value: admin.phoneNumber)
                    }
                }
            }
        }
        .navigationTitle(hospital.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Reset to original values
                        hospital = viewModel.hospitals.first(where: { $0.id == hospital.id }) ?? hospital
                        isEditing = false
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        do {
            try viewModel.updateHospital(hospital)
            isEditing = false
        } catch {
            print("Error updating hospital: \(error)")
        }
    }
}
