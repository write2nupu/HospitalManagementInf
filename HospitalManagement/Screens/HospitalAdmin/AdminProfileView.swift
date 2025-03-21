import SwiftUI

struct AdminProfile: Codable {
    var id: String = "ADM-2025-001"
    var name: String = "Dr. Admin"
    var hospitalName: String = "City General Hospital"
    var email: String = "admin@hospital.com"
    var phone: String = "9876543210"
    var password: String = "••••••••"
    var role: String
    
    init(id: String = "ADM-2025-001",
         name: String = "Dr. Admin",
         hospitalName: String = "City General Hospital",
         email: String = "admin@hospital.com",
         phone: String = "9876543210",
         password: String = "••••••••",
         role: String = "Hospital Administrator") {
        self.id = id
        self.name = name
        self.hospitalName = hospitalName
        self.email = email
        self.phone = phone
        self.password = password
        self.role = role
    }
}

struct EditContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    let admin: Admin
    let onSave: (Admin) -> Void
    
    @State private var email: String
    @State private var phone: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(admin: Admin, onSave: @escaping (Admin) -> Void) {
        self.admin = admin
        self.onSave = onSave
        _email = State(initialValue: admin.email)
        _phone = State(initialValue: admin.phone_number)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveChanges()
                }
            )
            .alert("Update Status", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveChanges() {
        // Validate email
        guard email.contains("@") else {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        // Validate phone
        guard phone.count >= 10 else {
            alertMessage = "Please enter a valid phone number"
            showAlert = true
            return
        }
        
        var updatedAdmin = admin
        updatedAdmin.email = email
        updatedAdmin.phone_number = phone
        
        onSave(updatedAdmin)
        alertMessage = "Profile updated successfully"
        showAlert = true
    }
}

struct ContactInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: AdminProfile
    @State private var isEditing = false
    @State private var email: String
    @State private var phone: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(profile: Binding<AdminProfile>) {
        self._profile = profile
        _email = State(initialValue: profile.wrappedValue.email)
        _phone = State(initialValue: profile.wrappedValue.phone)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Email")
                        Spacer()
                        if isEditing {
                            TextField("", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(profile.email)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Phone")
                        Spacer()
                        if isEditing {
                            TextField("", text: $phone)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(profile.phone)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Contact Information")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            )
            .alert("Update Status", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        isEditing = false
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveChanges() {
        // Validate email
        guard email.contains("@") else {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        // Validate phone
        guard phone.count >= 10 else {
            alertMessage = "Please enter a valid phone number"
            showAlert = true
            return
        }
        
        // Update profile
        profile.email = email
        profile.phone = phone
        
        // Save to UserDefaults or your backend
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "adminProfile")
        }
        
        alertMessage = "Profile updated successfully"
        showAlert = true
    }
}

struct AdminProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseController = SupabaseController()
    @State private var admin: Admin?
    @State private var showingContactSheet = false
    @State private var showingLogoutAlert = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("currentAdminId") private var currentAdminId: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                if let admin = admin {
                    Section("Admin Information") {
                        HStack {
                            Text("Admin ID")
                            Spacer()
                            Text(admin.id.uuidString)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(admin.fullName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Role")
                            Spacer()
                            Text("Hospital Administrator")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section("Contact Information") {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(admin.email)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Phone")
                            Spacer()
                            Text(admin.phone_number)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button(action: { showingContactSheet = true }) {
                            Text("Edit Contact Information")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showingContactSheet) {
                if let admin = admin {
                    EditContactSheet(admin: admin) { updatedAdmin in
                        Task {
                            await updateAdmin(updatedAdmin)
                        }
                    }
                }
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .task {
                await loadAdminProfile()
            }
        }
    }
    
    private func loadAdminProfile() async {
        if let adminId = UUID(uuidString: currentAdminId) {
            admin = await supabaseController.fetchAdminByUUID(adminId: adminId)
        }
    }
    
    private func updateAdmin(_ updatedAdmin: Admin) async {
        do {
            try await supabaseController.client
                .from("Admins")
                .update(updatedAdmin)
                .eq("id", value: updatedAdmin.id)
                .execute()
            
            admin = updatedAdmin
        } catch {
            print("Error updating admin: \(error)")
        }
    }
    
    private func logout() {
        // Clear user data
        currentAdminId = ""
        isLoggedIn = false
        dismiss()
    }
}

#Preview {
    AdminProfileView()
}
