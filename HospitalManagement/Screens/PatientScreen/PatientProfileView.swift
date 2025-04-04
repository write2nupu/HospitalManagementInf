//
//  PatientProfileView.swift
//  HospitalManagement
//
//  Created by Nupur on 21/03/25.
//

import SwiftUI

struct ProfileView: View {
    @Binding var patient: Patient
    @State private var patientDetails: PatientDetails?
    @State private var isLoading = true
    @State private var isEditing = false
    
    @State private var bloodGroup: String = ""
    @State private var allergies: String = ""
    @State private var existingMedicalRecord: String = ""
    @State private var currentMedication: String = ""
    @State private var pastSurgeries: String = ""
    @State private var emergencyContact: String = ""
    @State private var showLogoutAlert = false

    @StateObject private var supabase = SupabaseController()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile Header
                ZStack {
                    Color(.systemGray6)
                        .edgesIgnoringSafeArea(.top)
                        .frame(height: 180)
                    
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(AppConfig.buttonColor)
                            .clipShape(Circle())
                        
                        Text(patient.email)
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.top, 5)
                    }
                }
                
                // Profile Details Form
                Form {
                    Section(header: Text("Patient Information")) {
                        ProfileRow(title: "Full Name", value: patient.fullname)
                        ProfileRow(title: "Date of Birth", value: formattedDate(patient.dateofbirth))
                        ProfileRow(title: "Phone", value: patient.contactno)
                        ProfileRow(title: "Gender", value: patient.gender)
                    }
                    
                    if isLoading {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    } else {
                        Section(header: Text("Medical Information")) {
                            if isEditing {
                                TextField("Blood Group", text: $bloodGroup)
                                TextField("Allergies", text: $allergies)
                                TextField("Existing Medical Record", text: $existingMedicalRecord)
                                TextField("Current Medication", text: $currentMedication)
                                TextField("Past Surgeries", text: $pastSurgeries)
                                TextField("Emergency Contact", text: $emergencyContact)
                            } else {
                                ProfileRow(title: "Blood Group", value: patientDetails?.blood_group)
                                ProfileRow(title: "Allergies", value: patientDetails?.allergies)
                                ProfileRow(title: "Existing Medical Record", value: patientDetails?.existing_medical_record)
                                ProfileRow(title: "Current Medication", value: patientDetails?.current_medication)
                                ProfileRow(title: "Past Surgeries", value: patientDetails?.past_surgeries)
                                ProfileRow(title: "Emergency Contact", value: patientDetails?.emergency_contact)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            Text("Logout")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .alert(isPresented: $showLogoutAlert) {
                            Alert(
                                title: Text("Logout"),
                                message: Text("Are you sure you want to logout?"),
                                primaryButton: .destructive(Text("Logout")) {
                                    handleLogout()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Close") { dismiss() },
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task {
                            await saveUpdatedDetails()
                        }
                    } else {
                        enterEditMode()
                    }
                }
                .foregroundColor(.blue)
            )
            .task {
                await fetchPatientData()
            }
        }
    }
    
    private func fetchPatientData() async {
        do {
            // First fetch patient details using the patient ID
            if let fetchedPatient = try await supabase.fetchPatientDetails(patientId: patient.id) {
                // Update patient binding with latest data
                patient = fetchedPatient
                
                // Then fetch medical details using detail_id if available
                if let detailId = fetchedPatient.detail_id {
                    patientDetails = try await supabase.fetchPatientDetailsById(detailId: detailId)
                    
                    // Update local state with fetched details
                    if let details = patientDetails {
                        bloodGroup = details.blood_group ?? ""
                        allergies = details.allergies ?? ""
                        existingMedicalRecord = details.existing_medical_record ?? ""
                        currentMedication = details.current_medication ?? ""
                        pastSurgeries = details.past_surgeries ?? ""
                        emergencyContact = details.emergency_contact ?? ""
                    }
                }
            }
        } catch {
            print("Error fetching patient data:", error)
        }
        
        isLoading = false
    }
    
    private func enterEditMode() {
        isEditing = true
    }
    
    private func saveUpdatedDetails() async {
        guard let detailId = patient.detail_id else { return }
        
        let updatedDetails = PatientDetails(
            id: detailId,
            blood_group: bloodGroup,
            allergies: allergies,
            existing_medical_record: existingMedicalRecord,
            current_medication: currentMedication,
            past_surgeries: pastSurgeries,
            emergency_contact: emergencyContact
        )
        
        await supabase.updatePatientDetails(detailID: detailId, updatedDetails: updatedDetails)
        
        // Refresh the data
        await fetchPatientData()
        
        isEditing = false
    }
    
    private func handleLogout() {
        Task {
            do {
                // Sign out the user from Supabase authentication
                try await SupabaseController().client.auth.signOut()
                
                // Clear any stored user data
                UserDefaults.standard.removeObject(forKey: "currentUserId")
                UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                UserDefaults.standard.removeObject(forKey: "userRole")
                
                // Dismiss the profile sheet first
                dismiss()
                
                // Use UIApplication to restart the app's navigation from the beginning
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: UserRoleScreen())
                    window.makeKeyAndVisible()
                }
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    }
}

// Helper View for Profile Rows
struct ProfileRow: View {
    let title: String
    let value: String?
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.system(size: 16)) // Same font
                .foregroundColor(.primary) // Title in black
            Spacer()
            Text(value?.isEmpty == false ? value! : "")
                .font(.system(size: 16)) // Same font
                .foregroundColor(.gray) // Value in grey
        }
    }
}

// Helper function to format date correctly
func formattedDate(_ date: Date?) -> String {
    guard let date = date else { return "N/A" }
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter.string(from: date)
}
