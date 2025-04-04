import SwiftUI
import PostgREST

struct LocationResponse: Codable {
    let lat: String
    let lon: String
    let display_name: String
    
    var addressComponents: [String] {
        display_name.components(separatedBy: ", ")
    }
    
    var city: String {
        // Usually city is the third-to-last component
        let components = addressComponents
        return components.count >= 3 ? components[components.count - 3] : ""
    }
    
    var state: String {
        // State is usually the second-to-last component
        let components = addressComponents
        return components.count >= 2 ? components[components.count - 2] : ""
    }
}

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
                        .foregroundColor(AppConfig.fontColor)
                    Spacer()
                    StatusBadge(isActive: hospital.is_active)
                }
                
                // Location info
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppConfig.buttonColor)
                    Text("\(hospital.city), \(hospital.state)")
                        .font(.subheadline)
                        .foregroundColor(AppConfig.fontColor)
                }
                
                // Contact info
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(AppConfig.buttonColor)
                    Text(hospital.mobile_number)
                        .font(.subheadline)
                        .foregroundColor(AppConfig.fontColor)
                }
                
                // Admin info
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppConfig.buttonColor)
                    if let admin = adminDetails {
                        Text("Admin: \(admin.full_name)")
                            .font(.subheadline)
                            .foregroundColor(AppConfig.fontColor)
                    } else {
                        Text("Admin: Not Assigned")
                            .font(.subheadline)
                            .foregroundColor(AppConfig.fontColor)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppConfig.cardColor)
                    .shadow(color: AppConfig.shadowColor, radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
        .task {
            if let adminId = hospital.assigned_admin_id {
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
                .fill(isActive ? AppConfig.approvedColor : AppConfig.redColor)
                .frame(width: 8, height: 8)
            Text(isActive ? "Active" : "Inactive")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? AppConfig.approvedColor : AppConfig.redColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? AppConfig.approvedColor.opacity(0.1) : AppConfig.redColor.opacity(0.1))
        )
    }
}

struct SuperAdminProfileButton: View {
    @Binding var isShowingProfile: Bool
    
    var body: some View {
        Button(action: { isShowingProfile = true }) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(AppConfig.buttonColor)
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
    @State private var showSuccessAlert = false
    
    @State private var isLoadingLocation = false
    @State private var locationError: String? = nil
    
    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
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
                    TextField("Pincode (6 digits)", text: $pincode)
                        .keyboardType(.numberPad)
                        .onChange(of: pincode) { oldValue, newValue in
                            // Only allow numbers and limit to 6 digits
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                pincode = filtered
                            }
                            if filtered.count > 6 {
                                pincode = String(filtered.prefix(6))
                            }
                            
                            // Clear location if pincode is deleted
                            if filtered.isEmpty {
                                city = ""
                                state = ""
                                locationError = nil
                            }
                            // Fetch location when pincode is 6 digits
                            else if filtered.count == 6 {
                                fetchLocationFromPincode(filtered)
                            }
                        }
                    
                    if let error = locationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        TextField("City", text: $city)
                            .disabled(isLoadingLocation)
                        if isLoadingLocation {
                            ProgressView()
                                .padding(.horizontal, 8)
                        }
                    }
                    
                    TextField("State", text: $state)
                        .disabled(isLoadingLocation)
                    
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
                        .tint(AppConfig.buttonColor)
                }
            }
            .navigationTitle("Add Hospital")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { 
                    triggerHaptic(.warning)
                    dismiss() 
                }
                .foregroundColor(AppConfig.buttonColor),
                trailing: Button("Save") {
                    if isValidForm {
                        Task {
                            await saveHospital()
                        }
                    } else {
                        showingValidationAlert = true
                        triggerHaptic(.error)
                    }
                }
                .foregroundColor(AppConfig.buttonColor)
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
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Hospital has been successfully created")
            }
        }
    }
    
    private func saveHospital() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            // First create the hospital without admin
            let hospitalId = UUID()
            var hospital = Hospital(
                id: hospitalId,
                name: name,
                address: address,
                city: city,
                state: state,
                pincode: pincode,
                mobile_number: contact,
                email: email,
                license_number: licenseNumber,
                is_active: isActive,
                assigned_admin_id: nil  // Initially no admin
            )

            // Then create the admin
            let adminId = UUID()
            let initialPassword = generateRandomPassword()
            
            var admin = Admin(
                id: adminId,
                email: adminEmail,
                full_name: adminFullName,
                phone_number: adminPhone,
                hospital_id: hospitalId,  // Link to hospital
                is_first_login: true,
                initial_password: initialPassword
            )
            
            hospital.assigned_admin_id = admin.id
            
            print("Creating admin with ID: \(adminId) for hospital: \(hospitalId)")
            
            // Convert admin metadata to AnyJSON format
            let adminMetadata: [String: AnyJSON] = [
                "full_name": .string(adminFullName),
                "phone_number": .string(adminPhone),
                "role": .string("admin"),
                "hospital_id": .string(hospitalId.uuidString),
                "is_first_login": .bool(true),
                "is_active": .bool(true)
            ]
            
            // First sign up the admin using Supabase Auth
            do {
                let authResponse = try await supabaseController.client.auth.signUp(
                    email: adminEmail,
                    password: initialPassword,
                    data: adminMetadata
                )
                
                // Update admin ID to match auth user ID
                admin.id = authResponse.user.id
                hospital.assigned_admin_id = admin.id
                
                print("Admin auth account created with ID:", authResponse.user.id)
            } catch {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create admin account: \(error.localizedDescription)"])
            }
            
            // Then create the admin record in the database
            try await supabaseController.client
                .from("Admin")
                .insert(admin)
                .execute()
                
            print("Admin created successfully")
                
            print("Creating hospital with ID: \(hospitalId)")

            // Add hospital to Supabase
            try await supabaseController.client
                .from("Hospital")
                .insert(hospital)
                .execute()
            
            print("Hospital created successfully")
            
            // Send admin credentials via email
            do {
                try await EmailService.shared.sendAdminCredentials(to: admin, hospitalName: hospital.name)
                print("Admin credentials sent successfully to \(admin.email)")
            } catch {
                print("Failed to send admin credentials email: \(error)")
                // Note: We don't throw here since the hospital and admin were created successfully
            }
            
            // After successful save
            triggerHaptic()
            showSuccessAlert = true
            
            // Refresh the hospitals list
            if let parentViewModel = viewModel as? HospitalManagementViewModel {
                parentViewModel.hospitals = await supabaseController.fetchHospitals()
            }
        } catch {
            validationMessage = "Error saving hospital: \(error.localizedDescription)"
            triggerHaptic(.error)
            showingValidationAlert = true
        }
    }
    
    private func generateRandomPassword() -> String {
        let numbers = "9876543210"
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let specialCharacters = "!@#$%^&*()-_=+[]{}|;:,.<>?/"

        let randomNumber = numbers.randomElement()!
        let randomLetter = letters.randomElement()!
        let randomSpecialChar = specialCharacters.randomElement()!

        let allCharacters = numbers + letters + specialCharacters
        let remainingChars = (0..<5).map { _ in allCharacters.randomElement()! }

        let passwordArray = [randomNumber, randomLetter, randomSpecialChar] + remainingChars
        return String(passwordArray.shuffled())
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
        
        // Additional validation for location
        if !pincode.isEmpty && locationError != nil {
            validationMessage = "Please enter a valid pincode"
            return false
        }
        
        return true
    }
    
    private func fetchLocationFromPincode(_ pincode: String) {
        // Clear existing location data if pincode is empty
        if pincode.isEmpty {
            city = ""
            state = ""
            locationError = nil
            return
        }
        
        isLoadingLocation = true
        locationError = nil
        
        let urlString = "https://nominatim.openstreetmap.org/search?postalcode=\(pincode)&countrycodes=IN&format=json"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingLocation = false
                
                if let error = error {
                    locationError = "Network error: \(error.localizedDescription)"
                    city = ""
                    state = ""
                    return
                }
                
                guard let data = data else {
                    locationError = "No data received"
                    city = ""
                    state = ""
                    return
                }
                
                do {
                    let locations = try JSONDecoder().decode([LocationResponse].self, from: data)
                    if let location = locations.first {
                        city = location.city
                        state = location.state
                        
                        // If no city/state found for valid pincode
                        if city.isEmpty && state.isEmpty {
                            locationError = "No location found for this pincode"
                        }
                    } else {
                        locationError = "Invalid pincode"
                        city = ""
                        state = ""
                    }
                } catch {
                    locationError = "Error processing location data"
                    city = ""
                    state = ""
                }
            }
        }.resume()
    }
}

struct QuickActionCard: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppConfig.buttonColor)
                
                Text("Add Hospital")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.fontColor)
                
                Text("Create a new hospital profile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppConfig.cardColor)
                    .shadow(color: AppConfig.shadowColor, radius: 10, x: 0, y: 5)
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
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var filteredHospitals: [Hospital] {
        let sorted = (searchText.isEmpty ? viewModel.hospitals : viewModel.hospitals.filter { hospital in
            hospital.name.localizedCaseInsensitiveContains(searchText) ||
            hospital.city.localizedCaseInsensitiveContains(searchText) ||
            hospital.state.localizedCaseInsensitiveContains(searchText)
        }).sorted { h1, h2 in
            if h1.is_active == h2.is_active {
                return h1.name < h2.name
            }
            return h1.is_active && !h2.is_active
        }
        return sorted
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 24) {
                        // Quick Actions Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.headline)
                                .foregroundColor(AppConfig.fontColor)
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
                                    .foregroundColor(AppConfig.fontColor)
                                Spacer()
                                NavigationLink("See All", destination: HospitalList(hospitals: filteredHospitals, viewModel: viewModel))
                                    .foregroundColor(AppConfig.buttonColor)
                            }
                            .padding(.horizontal)
                            
                            if viewModel.hospitals.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "building.2")
                                        .font(.system(size: 50))
                                        .foregroundColor(AppConfig.buttonColor)
                                    Text("No hospitals yet")
                                        .font(.title3)
                                        .foregroundColor(AppConfig.fontColor)
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
            }
            .background(AppConfig.backgroundColor)
            .navigationTitle("Dashboard")
            .navigationBarBackButtonHidden(true)
            .searchable(text: $searchText, prompt: "Search hospitals...")
            .navigationBarItems(trailing: SuperAdminProfileButton(isShowingProfile: $showingProfile))
            .sheet(isPresented: $showingAddHospital) {
                AddHospitalView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingProfile) {
                SuperAdminProfileView()
            }
            .refreshable {
                await loadHospitals()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await loadHospitals()
        }
    }
    
    private func loadHospitals() async {
        isLoading = true
        do {
            let fetchedHospitals = await supabaseController.fetchHospitals()
            viewModel.hospitals = fetchedHospitals
        }
        isLoading = false
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
        .background(AppConfig.backgroundColor)
        .navigationTitle("All Hospitals")
        .navigationBarTitleDisplayMode(.inline)
        
    }
}

#Preview {
    ContentView()
        .environmentObject(HospitalManagementViewModel())
}

