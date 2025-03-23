//
//  PatientProfileView.swift
//  HospitalManagement
//
//  Created by Nupur on 21/03/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var supabaseController = SupabaseController()
    @Binding var patient: Patient
    var patientDetails: PatientDetails
    @State private var patients: [Patient] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    profileRow(title: "Full Name", value: patient.fullName)
                    profileRow(title: "gender", value: patient.gender)
                    profileRow(title: "Date of Birth", value: "\(patient.dateOfBirth)")
                    profileRow(title: "Phone Number", value: patient.phoneNumber)
                    profileRow(title: "E-Mail", value: patient.email)
                }
                

                Section(header: Text("Medical Information")) {
                    if let patientBloodGroup = patientDetails.bloodGroup {
                        profileRow(title: "Blood Group", value: patientBloodGroup)
                    }
                    if let patientAllergies = patientDetails.allergies {
                        profileRow(title: "Allergies", value: patientAllergies)
                    }
                    if let patientExistingMedicalRecord = patientDetails.existingMedicalRecord {
                        profileRow(title: "Existing Medical Record", value: patientExistingMedicalRecord)
                    }
                    if let patientCurrentMedication = patientDetails.currentMedication {
                        profileRow(title: "Current Medication", value: patientCurrentMedication)
                    }
                    if let patientPastSurgeries = patientDetails.pastSurgeries {
                        profileRow(title: "Past Surgeries", value: patientPastSurgeries)
                    }
                    if let patientEmergencyContact = patientDetails.bloodGroup {
                        profileRow(title: "Emergency Contact", value: patientEmergencyContact)

                    }
                }
            }
            .navigationTitle("Patient Profile")
            .task {
                // Fetch patient details
                if let currentPatientId = patient.detailId {
                    patients = await supabaseController.fetchPatients()
                }
            }
            //patients.
        }
    }
    
    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title).fontWeight(.none)
            Spacer()
            Text(value).foregroundColor(.gray)
        }
    }
}
