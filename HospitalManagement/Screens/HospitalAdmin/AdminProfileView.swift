import SwiftUI

struct AdminProfile: Codable {
    var id: String = "ADM-2025-001"
    var name: String = "Dr. Admin"
    var hospitalName: String = "City General Hospital"
    var email: String = "admin@hospital.com"
    var phone: String = "9876543210"
    var password: String = "••••••••"
    let role: String = "Hospital Administrator"
}

struct EditContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: AdminProfile
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
                .foregroundColor(.blue)
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
                .foregroundColor(.blue)
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
    @State private var profile = AdminProfile()
    @State private var showingContactSheet = false
    @State private var showingLogoutAlert = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Admin Information") {
                    HStack {
                        Text("Admin ID")
                        Spacer()
                        Text(profile.id)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(profile.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Hospital")
                        Spacer()
                        Text(profile.hospitalName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(profile.role)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Contact Information") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(profile.email)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(profile.phone)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: { showingContactSheet = true }) {
                        Text("Edit Contact Information")
                    }
                    .foregroundColor(.blue)
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
                ContactInfoSheet(profile: $profile)
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .onAppear {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "adminProfile"),
           let decoded = try? JSONDecoder().decode(AdminProfile.self, from: data) {
            profile = decoded
        }
    }
    
    private func logout() {
        // Clear user data
        UserDefaults.standard.removeObject(forKey: "adminProfile")
        isLoggedIn = false
        dismiss()
    }
}

#Preview {
    AdminProfileView()
}