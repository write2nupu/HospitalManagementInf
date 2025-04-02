import SwiftUI

struct UpdateQualificationsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabaseController = SupabaseController()
    
    let doctor: Doctor  // Doctor whose qualifications need to be updated
    
    @State private var selectedQualification: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // List of qualifications for doctors
    let qualificationsList = [
        "MBBS", "MD", "MS", "DO", "DM", "MCh", "BDS", "MDS", "DNB", "PhD (Medical)", "Diploma in Medicine"
    ]
    
    var hasChanged: Bool {
        selectedQualification != doctor.qualifications
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Current Qualifications")) {
                    Text(doctor.qualifications)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Update Qualifications")) {
                    Picker("Select Qualification", selection: $selectedQualification) {
                        ForEach(qualificationsList, id: \.self) { qualification in
                            Text(qualification).tag(qualification)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Update Qualifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: updateQualifications) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!hasChanged || isLoading) // Enable only if changed
                }
            }
        }
        .onAppear {
            selectedQualification = doctor.qualifications // Preselect current qualification
        }
    }
    
    private func updateQualifications() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await supabaseController.client
                    .from("Doctor")
                    .update(["qualifications": selectedQualification])
                    .eq("id", value: doctor.id.uuidString)
                    .execute()
                
                isLoading = false
                dismiss() // Close the screen after update
            } catch {
                isLoading = false
                errorMessage = "Failed to update qualifications. Try again."
                print("Error updating qualifications:", error)
            }
        }
    }
}

//#Preview {
//    UpdateQualificationsView(doctor: Doctor(id: UUID(), full_name: "Dr. John Doe", qualifications: "MBBS"))
//}
