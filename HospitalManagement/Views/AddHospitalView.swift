struct AddHospitalView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var pincode = ""
    @State private var mobileNumber = ""
    @State private var email = ""
    @State private var licenseNumber = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Hospital Name", text: $name)
                TextField("Address", text: $address)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Pincode", text: $pincode)
                TextField("Mobile Number", text: $mobileNumber)
                TextField("Email", text: $email)
                TextField("License Number", text: $licenseNumber)
            }
            .navigationTitle("Add Hospital")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHospital()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveHospital() {
        let hospital = Hospital(
            id: UUID(),
            name: name,
            address: address,
            city: city,
            state: state,
            pincode: pincode,
            mobileNumber: mobileNumber,
            email: email,
            licenseNumber: licenseNumber,
            isActive: true,
            assignedAdminId: nil
        )
        
        do {
            try viewModel.addHospital(hospital)
            dismiss()
        } catch {
            // Handle error
            print("Error saving hospital: \(error)")
        }
    }
} 