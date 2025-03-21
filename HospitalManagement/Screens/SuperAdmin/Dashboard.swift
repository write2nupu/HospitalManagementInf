//
//  Dashboard.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import SwiftUI

struct HospitalCard: View {
    let hospital: Hospital
    let viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var adminDetails: Admin?
    
    var body: some View {
        NavigationLink {
            HospitalDetailView(viewModel: viewModel, hospital: hospital)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header with name and status
                HStack {
                    Text(hospital.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    StatusBadge(isActive: hospital.isActive)
                }
                
                // Location info
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.mint)
                    Text("\(hospital.city), \(hospital.state)")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                // Contact info
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.mint)
                    Text(hospital.mobileNumber)
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                // Admin info
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.mint)
                    if let admin = adminDetails {
                        Text("Admin: \(admin.fullName)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    } else {
                        Text("Admin: Not Assigned")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
        .task {
            if let adminId = hospital.assignedAdminId {
                adminDetails = await supabaseController.fetchAdminByUUID(adminId: adminId)
            }
        }
    }
}

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isActive ? "Active" : "Inactive")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

struct SuperAdminProfileButton: View {
    @Binding var isShowingProfile: Bool
    
    var body: some View {
        Button(action: { isShowingProfile = true }) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.mint)
        }
    }
}

struct SuperAdminProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Super Admin Information") {
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text("Super Admin")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email:")
                        Spacer()
                        Text("admin@example.com")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct AddHospitalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    
    @State private var name = ""
    @State private var licenseNumber = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var pincode = ""
    @State private var contact = ""
    @State private var email = ""
    @State private var isActive = true
    
    // Admin Details
    @State private var adminFullName = ""
    @State private var adminEmail = ""
    @State private var adminPhone = ""
    
    // Validation States
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hospital Details")) {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("License Number (XXX-XXX-XXX)", text: $licenseNumber)
                        .textInputAutocapitalization(.characters)
                    TextField("Address", text: $address)
                        .textInputAutocapitalization(.words)
                    TextField("City", text: $city)
                        .textInputAutocapitalization(.words)
                    TextField("State", text: $state)
                        .textInputAutocapitalization(.words)
                    TextField("Pincode (6 digits)", text: $pincode)
                        .keyboardType(.numberPad)
                    TextField("Contact (10 digits)", text: $contact)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("Admin Details")) {
                    TextField("Full Name", text: $adminFullName)
                        .textInputAutocapitalization(.words)
                    TextField("Email", text: $adminEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone Number (10 digits)", text: $adminPhone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Status")) {
                    Toggle("Active", isOn: $isActive)
                        .tint(.mint)
                }
            }
            .navigationTitle("Add Hospital")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.mint),
                trailing: Button("Save") {
                    if isValidForm {
                        Task {
                            await saveHospital()
                        }
                    } else {
                        showingValidationAlert = true
                    }
                }
                .foregroundColor(.mint)
                .disabled(isSubmitting)
            )
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func saveHospital() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            // First create the admin
            let adminId = UUID()
            let admin = Admin(
                id: adminId,
                email: adminEmail,
                fullName: adminFullName,
                phoneNumber: adminPhone,
                hospitalId: nil,
                isFirstLogin: true,
                initialPassword: generateRandomPassword()
            )
            
            // Create the hospital
            let hospital = Hospital(
                id: UUID(),
                name: name,
                address: address,
                city: city,
                state: state,
                pincode: pincode,
                mobileNumber: contact,
                email: email,
                licenseNumber: licenseNumber,
                isActive: isActive,
                assignedAdminId: adminId
            )
            
            // Add admin to Supabase
            try await supabaseController.client
                .from("Admins")
                .insert(admin)
                .execute()
            
            // Add hospital to Supabase
            try await supabaseController.client
                .from("Hospitals")
                .insert(hospital)
                .execute()
            
            dismiss()
        } catch {
            validationMessage = "Error saving hospital: \(error.localizedDescription)"
            showingValidationAlert = true
        }
    }
    
    private func generateRandomPassword() -> String {
        let digits = "0123456789"
        return String((0..<6).map { _ in digits.randomElement()! })
    }
    
    private var isValidForm: Bool {
        // Basic presence check
        guard !name.isEmpty, !licenseNumber.isEmpty, !address.isEmpty,
              !city.isEmpty, !state.isEmpty, !pincode.isEmpty,
              !contact.isEmpty, !email.isEmpty,
              !adminFullName.isEmpty, !adminEmail.isEmpty, !adminPhone.isEmpty else {
            validationMessage = "All fields are required"
            return false
        }
        
        // License number validation (assuming format: XXX-XXX-XXX)
        let licensePattern = "^[A-Z0-9]{3}-[A-Z0-9]{3}-[A-Z0-9]{3}$"
        if licenseNumber.range(of: licensePattern, options: .regularExpression) == nil {
            validationMessage = "License number should be in XXX-XXX-XXX format"
            return false
        }
        
        // Email validation
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        if email.range(of: emailPattern, options: .regularExpression) == nil {
            validationMessage = "Please enter a valid email address"
            return false
        }
        if adminEmail.range(of: emailPattern, options: .regularExpression) == nil {
            validationMessage = "Please enter a valid admin email address"
            return false
        }
        
        // Phone number validation (10 digits)
        let phonePattern = "^[0-9]{10}$"
        if contact.range(of: phonePattern, options: .regularExpression) == nil {
            validationMessage = "Phone number should be 10 digits"
            return false
        }
        if adminPhone.range(of: phonePattern, options: .regularExpression) == nil {
            validationMessage = "Admin phone number should be 10 digits"
            return false
        }
        
        // Pincode validation (6 digits)
        let pincodePattern = "^[0-9]{6}$"
        if pincode.range(of: pincodePattern, options: .regularExpression) == nil {
            validationMessage = "Pincode should be 6 digits"
            return false
        }
        
        return true
    }
}

struct QuickActionCard: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.mint)
                
                Text("Add Hospital")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Create a new hospital profile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = HospitalManagementViewModel()
    @StateObject private var supabaseController = SupabaseController()
    @State private var showingAddHospital = false
    @State private var showingProfile = false
    @State private var searchText = ""
    @State private var showingAllHospitals = false
    @State private var hospitals: [Hospital] = []
    
    var filteredHospitals: [Hospital] {
        let sorted = (searchText.isEmpty ? hospitals : hospitals.filter { hospital in
            hospital.name.localizedCaseInsensitiveContains(searchText) ||
            hospital.city.localizedCaseInsensitiveContains(searchText) ||
            hospital.state.localizedCaseInsensitiveContains(searchText)
        }).sorted { h1, h2 in
            if h1.isActive == h2.isActive {
                return h1.name < h2.name
            }
            return h1.isActive && !h2.isActive
        }
        return sorted
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Actions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        QuickActionCard {
                            showingAddHospital = true
                        }
                        .padding(.horizontal)
                    }
                    
                    // Hospitals Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Hospitals")
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                            NavigationLink("See All", destination: HospitalList(hospitals: filteredHospitals, viewModel: viewModel))
                                .foregroundColor(.mint)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.hospitals.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 50))
                                    .foregroundColor(.mint)
                                Text("No hospitals yet")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(filteredHospitals) { hospital in
                                        HospitalCard(hospital: hospital, viewModel: viewModel)
                                            .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .searchable(text: $searchText, prompt: "Search hospitals...")
            .navigationBarItems(trailing: SuperAdminProfileButton(isShowingProfile: $showingProfile))
            .sheet(isPresented: $showingAddHospital) {
                AddHospitalView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingProfile) {
                SuperAdminProfileView()
            }
        }
        .task {
            let fetchedHospitals = await supabaseController.fetchHospitals()
            hospitals = fetchedHospitals
        }
    }
}

struct HospitalList: View {
    let hospitals: [Hospital]
    let viewModel: HospitalManagementViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(hospitals) { hospital in
                    HospitalCard(hospital: hospital, viewModel: viewModel)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("All Hospitals")
    }
}

#Preview {
    ContentView()
        .environmentObject(HospitalManagementViewModel())
}

