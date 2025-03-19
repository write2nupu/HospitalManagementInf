//
//  HospitalDetailView.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import SwiftUI

struct HospitalDetailView: View {
    @ObservedObject var viewModel: HospitalViewModel
    @State var hospital: hospitals
    @State private var isActive: Bool
    
    init(viewModel: HospitalViewModel, hospital: hospitals) {
        self.viewModel = viewModel
        _hospital = State(initialValue: hospital)
        _isActive = State(initialValue: hospital.isActive)
    }
    
    var body: some View {
        List {
            Section("Hospital Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(hospital.name)
                        .font(.title2)
                        .bold()
                    Text(hospital.address)
                    Text("\(hospital.city), \(hospital.state)")
                    Text("PIN: \(hospital.pincode)")
                    Text("Contact: \(hospital.contact)")
                    Text("Email: \(hospital.email)")
                }
                .padding(.vertical, 4)
            }
            
            Section("Admin Details") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                        Text(hospital.adminName)
                    }
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.orange)
                        Text(hospital.adminEmail)
                    }
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                        Text(hospital.adminPhone)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Status") {
                Toggle("Active", isOn: $isActive)
                    .tint(isActive ? .green : .red)
                    .onChange(of: isActive) { oldValue, newValue in
                        updateHospitalActive(newValue)
                    }
            }
            
            Section("Login Credentials") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username: \(hospital.email)")
                    Text("Password: \(hospital.password)")
                        .monospaced()
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(hospital.name)
    }
    
    private func updateHospitalActive(_ newValue: Bool) {
        var updatedHospital = hospital
        updatedHospital.isActive = newValue
        viewModel.updateHospital(updatedHospital)
        hospital = updatedHospital
    }
}
