struct AdminManagementView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @State private var showAddAdmin = false
    
    var body: some View {
        List {
            ForEach(viewModel.admins) { admin in
                AdminRowView(admin: admin)
            }
        }
        .navigationTitle("Admins")
        .toolbar {
            Button("Add Admin") {
                showAddAdmin = true
            }
        }
        .sheet(isPresented: $showAddAdmin) {
            AddAdminView()
        }
    }
}

struct AddAdminView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Full Name", text: $fullName)
                TextField("Email", text: $email)
                TextField("Phone Number", text: $phoneNumber)
            }
            .navigationTitle("Add Admin")
            .toolbar {
                Button("Save") {
                    saveAdmin()
                }
            }
        }
    }
    
    private func saveAdmin() {
        let admin = Admin(
            id: UUID(),
            email: email,
            fullName: fullName,
            phoneNumber: phoneNumber,
            hospitalId: nil,
            isFirstLogin: true,
            initialPassword: viewModel.generateRandomPassword()
        )
        
        do {
            try viewModel.addAdmin(admin)
            dismiss()
        } catch {
            print("Error saving admin: \(error)")
        }
    }
} 