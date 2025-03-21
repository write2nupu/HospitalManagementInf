import SwiftUI

struct AddDepartmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseController()
    @State private var departmentName = ""
    @State private var description = ""
    @State private var fees: Double = 0.0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Department Name", text: $departmentName)
                TextField("Description", text: $description)
                TextField("Consultation Fee", value: $fees, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
            } footer: {
                Text("Enter the department details")
            }
        }
        .navigationTitle("Add Department")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await saveDepartment()
                    }
                }
                .disabled(departmentName.isEmpty || fees <= 0)
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveDepartment() async {
        let newDepartment = Department(
            id: UUID(),
            name: departmentName,
            description: description.isEmpty ? nil : description,
            hospital_id: getCurrentHospitalId(),
            fees: fees
        )
        
        do {
            try await supabaseController.client
                .from("Departments")
                .insert(newDepartment)
                .execute()
            
            alertMessage = "Department added successfully"
            showAlert = true
        } catch {
            alertMessage = "Error adding department: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // Helper function to get current hospital ID (implement based on your auth system)
    private func getCurrentHospitalId() -> UUID? {
        // Implement this based on your authentication system
        // For example, get it from UserDefaults or your auth state
        return nil // Replace with actual implementation
    }
} 
