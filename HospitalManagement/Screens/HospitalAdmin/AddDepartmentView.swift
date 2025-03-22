import SwiftUI

struct AddDepartmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var departmentName = ""
    @State private var description = ""
    @State private var feesString = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var fees: Double? {
        // Remove "$" and any whitespace, then convert to Double
        let cleanString = feesString.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleanString)
    }
    
    private var isFormValid: Bool {
        !departmentName.isEmpty && fees != nil && (fees ?? 0) > 0
    }
    
    var body: some View {
        Form {
            Section("Department Information") {
                TextField("Department Name", text: $departmentName)
                    .autocapitalization(.words)
                TextField("Description", text: $description)
                TextField("Consultation Fee ($)", text: $feesString)
                    .keyboardType(.decimalPad)
                    .onChange(of: feesString) { newValue in
                        // Clean the input to only allow numbers and decimal point
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered != newValue {
                            feesString = filtered
                        }
                        // Add "$" prefix if needed
                        if !feesString.hasPrefix("$") && !feesString.isEmpty {
                            feesString = "$" + feesString
                        }
                    }
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
                    saveDepartment()
                }
                .disabled(!isFormValid)
                .foregroundColor(.blue)
            }
        }
        .alert("Department Status", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveDepartment() {
        guard !departmentName.isEmpty else {
            alertMessage = "Please enter a department name"
            showAlert = true
            return
        }
        
        guard let fees = fees, fees > 0 else {
            alertMessage = "Please enter a valid consultation fee"
            showAlert = true
            return
        }
        
        let department = Department(
            id: UUID(),
            name: departmentName,
            description: description.isEmpty ? nil : description,
            hospital_id: nil,
            fees: fees
        )
        
        do {
            try viewModel.addDepartment(department)
            alertMessage = "Department added successfully"
            showAlert = true
        } catch {
            alertMessage = "Failed to add department: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Preview
struct AddDepartmentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddDepartmentView()
                .environmentObject(HospitalManagementViewModel())
        }
    }
} 
