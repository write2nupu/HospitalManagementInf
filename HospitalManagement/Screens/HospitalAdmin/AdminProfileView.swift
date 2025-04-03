import SwiftUI

struct AdminProfile: Codable {
    var id: String = ""
    var name: String = ""
    var hospitalName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var role: String = ""
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
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var admin: Admin?
    @State private var hospital: Hospital?
    @State private var showingPhoneEdit = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isEditing = false
    @State private var editedHospital: Hospital?
    
    // Logout related states
    @State private var isLoggedOut = false
    @State private var showLogoutAlert = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var userRole: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading profile...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    Form {
                        if let admin = admin, let hospital = hospital {
                            Section("Admin Information") {
                                ProfileDetailRow(title: "Name", value: admin.full_name)
                                ProfileDetailRow(title: "Hospital", value: hospital.name)
                                ProfileDetailRow(title: "Role", value: "Hospital Administrator")
                            }
                            
                            Section("Contact Information") {
                                ProfileDetailRow(title: "Email", value: admin.email)
                                Button(action: { showingPhoneEdit = true }) {
                                    HStack {
                                        Text("Phone")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(admin.phone_number)
                                            .foregroundColor(.primary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            Section("Hospital Information") {
                                if isEditing {
                                    TextField("Address", text: Binding(
                                        get: { editedHospital?.address ?? hospital.address },
                                        set: { editedHospital?.address = $0 }
                                    ))
                                    TextField("City", text: Binding(
                                        get: { editedHospital?.city ?? hospital.city },
                                        set: { editedHospital?.city = $0 }
                                    ))
                                    TextField("State", text: Binding(
                                        get: { editedHospital?.state ?? hospital.state },
                                        set: { editedHospital?.state = $0 }
                                    ))
                                    TextField("Pin Code", text: Binding(
                                        get: { editedHospital?.pincode ?? hospital.pincode },
                                        set: { editedHospital?.pincode = $0 }
                                    ))
                                    TextField("License Number", text: Binding(
                                        get: { editedHospital?.license_number ?? hospital.license_number },
                                        set: { editedHospital?.license_number = $0 }
                                    ))
                                    Toggle("Active", isOn: Binding(
                                        get: { editedHospital?.is_active ?? hospital.is_active },
                                        set: { editedHospital?.is_active = $0 }
                                    ))
                                } else {
                                    ProfileDetailRow(title: "Address", value: hospital.address)
                                    ProfileDetailRow(title: "City", value: hospital.city)
                                    ProfileDetailRow(title: "State", value: hospital.state)
                                    ProfileDetailRow(title: "Pin Code", value: hospital.pincode)
                                    ProfileDetailRow(title: "License Number", value: hospital.license_number)
                                    ProfileDetailRow(title: "Status", value: hospital.is_active ? "Active" : "Inactive")
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
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(
                leading: Button("Done") { dismiss() },
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveHospitalChanges()
                    } else {
                        startEditing()
                    }
                }
            )
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .fullScreenCover(isPresented: .constant(isLoggedOut)) {
                UserRoleScreen()
            }
            .sheet(isPresented: $showingPhoneEdit) {
                EditPhoneSheet(admin: $admin, supabaseController: supabaseController) {
                    Task {
                        await loadProfile()
                    }
                }
            }
            .onAppear {
                Task {
                    await loadProfile()
                }
            }
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let (fetchedAdmin, fetchedHospital) = try await supabaseController.fetchAdminProfile() {
                await MainActor.run {
                    self.admin = fetchedAdmin
                    self.hospital = fetchedHospital
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Could not find admin profile"
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error loading profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func handleLogout() {
        userRole = nil
        isLoggedIn = false
        NotificationCenter.default.post(name: .init("LogoutNotification"), object: nil)
        isLoggedOut = true
    }
    
    private func startEditing() {
        editedHospital = hospital
        isEditing = true
    }
    
    private func saveHospitalChanges() {
        guard let updatedHospital = editedHospital else { return }
        
        Task {
            do {
                try await supabaseController.updateHospital(updatedHospital)
                await MainActor.run {
                    self.hospital = updatedHospital
                    isEditing = false
                }
            } catch {
                print("Error updating hospital: \(error.localizedDescription)")
            }
        }
    }
}

struct EditPhoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var admin: Admin?
    let supabaseController: SupabaseController
    let onUpdate: () -> Void
    @State private var phoneNumber: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var isPhoneNumberValid: Bool {
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        TextField("Phone Number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .textContentType(.telephoneNumber)
                        
                        if !phoneNumber.isEmpty {
                            Image(systemName: isPhoneNumberValid ? "checkmark.circle.fill" : "x.circle.fill")
                                .foregroundColor(isPhoneNumberValid ? .green : .red)
                        }
                    }
                } header: {
                    Text("Edit Phone Number")
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(!isPhoneNumberValid)
                }
            }
            .navigationTitle("Edit Phone")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .alert("Update Status", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        if var updatedAdmin = admin {
                            updatedAdmin.phone_number = phoneNumber
                            admin = updatedAdmin
                        }
                        onUpdate()
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                phoneNumber = admin?.phone_number ?? ""
            }
        }
    }
    
    private func saveChanges() {
        guard isPhoneNumberValid else {
            alertMessage = "Please enter a valid 10-digit phone number"
            showAlert = true
            return
        }
        
        guard var updatedAdmin = admin else { return }
        updatedAdmin.phone_number = phoneNumber
        
        Task {
            do {
                try await supabaseController.updateAdmin(updatedAdmin)
                await MainActor.run {
                    alertMessage = "Phone number updated successfully"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to update phone number: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

struct ProfileDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    AdminProfileView()
}
