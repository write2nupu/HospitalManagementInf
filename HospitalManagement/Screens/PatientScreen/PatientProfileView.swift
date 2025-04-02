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
    @State private var isEditing = false  // Track edit mode

    @State private var bloodGroup: String = ""
    @State private var allergies: String = ""
    @State private var existingMedicalRecord: String = ""
    @State private var currentMedication: String = ""
    @State private var pastSurgeries: String = ""
    @State private var emergencyContact: String = ""

    @StateObject private var supabase = SupabaseController()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Grey Background with Profile Image & Email
                ZStack {
                    Color(.systemGray6)
                        .edgesIgnoringSafeArea(.top)
                        .frame(height: 180)

                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.mint)
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

                    // Logout Button Section
                    Section {
                        Button(action: {
                            handleLogout()
                        }) {
                            Text("Logout")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.red)
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
                await fetchPatientDetails()
            }
        }
    }

    private func fetchPatientDetails() async {
        guard let detailID = patient.detail_id else {
            DispatchQueue.main.async { self.isLoading = false }
            return
        }

        let allDetails = await supabase.fetchPatientDetails()
        DispatchQueue.main.async {
            self.patientDetails = allDetails.first(where: { $0.id == detailID })
            self.isLoading = false

            if let details = self.patientDetails {
                self.bloodGroup = details.blood_group ?? ""
                self.allergies = details.allergies ?? ""
                self.existingMedicalRecord = details.existing_medical_record ?? ""
                self.currentMedication = details.current_medication ?? ""
                self.pastSurgeries = details.past_surgeries ?? ""
                self.emergencyContact = details.emergency_contact ?? ""
            }
        }
    }

    private func enterEditMode() {
        isEditing = true
    }

    private func saveUpdatedDetails() async {
        guard let detailID = patient.detail_id else { return }

        let updatedDetails = PatientDetails(
            id: detailID,
            blood_group: bloodGroup,
            allergies: allergies,
            existing_medical_record: existingMedicalRecord,
            current_medication: currentMedication,
            past_surgeries: pastSurgeries,
            emergency_contact: emergencyContact
        )

        await supabase.updatePatientDetails(detailID: detailID, updatedDetails: updatedDetails)

        // Ensure UI updates with latest data
        await fetchPatientDetails()

        DispatchQueue.main.async {
            self.isEditing = false
        }
    }

    private func handleLogout() {
        // Post a notification that will be observed by the app
        NotificationCenter.default.post(
            name: NSNotification.Name("LogoutNotification"),
            object: nil
        )
        
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
                .foregroundColor(.black) // Title in black
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
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}
