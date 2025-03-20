import SwiftUI

// Doctor Profile Data Model
struct Doctor: Identifiable {
    let id: UUID = UUID()
    var name: String
    var specialization: String
    var qualifications: String
    var experience: Int
    var hospitalAffiliations: [String]
    var consultationFee: Double
    var phoneNumber: String
    var email: String
    var availableSlots: [String]
    var languagesSpoken: [String]?
    var profileImage: String? // Store image URL or asset name
}


struct DoctorProfileView: View {
    @State var doctor: Doctor = Doctor(
        name: "Dr. Anubhav Dubey",
        specialization: "Cardiologist",
        qualifications: "MBBS, MD",
        experience: 10,
        hospitalAffiliations: ["Apollo"],
        consultationFee: 500.0,
        phoneNumber: "9876543210",
        email: "doctor@example.com",
        availableSlots: ["Morning", "Evening"]
    )
    
    @State private var isLoggedOut = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Available Slots")) {
                    ForEach(doctor.availableSlots, id: \.self) { slot in
                        slotSetUp(slot: slot, isAvailable: checkAvailability(for: slot))
                    }
                }

                
                Section(header: Text("Consultation Fee")) {
                    profileRow(title: "Fee", value: "₹\(String(format: "%.2f", doctor.consultationFee))")
                }
                
                Section(header: Text("Basic Information")) {
                    profileRow(title: "Full Name", value: doctor.name)
                    profileRow(title: "Specialization", value: doctor.specialization)
                    profileRow(title: "Qualifications", value: doctor.qualifications)
                    profileRow(title: "Experience", value: "\(doctor.experience) years")
                }
                
                Section(header: Text("Hospital Affiliations")) {
                    ForEach(doctor.hospitalAffiliations, id: \.self) { affiliation in
                        Text(affiliation)
                    }
                }
                
                Section(header: Text("Contact Information")) {
                    profileRow(title: "Phone", value: doctor.phoneNumber)
                    profileRow(title: "Email", value: doctor.email)
                }
                
                
                Section {
                    NavigationLink(destination: updatePassword()) {
                        Text("Update Password")
                            .foregroundColor(AppConfig.buttonColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    Button(action: handleLogout) {
                        Text("Logout")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Doctor Profile")
            .tint(AppConfig.buttonColor)
            .fullScreenCover(isPresented: .constant(isLoggedOut)) {
                UserRoleScreen()
            }
        }
    }
    
    // ✅ Reusable Profile Row Component
    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title).fontWeight(.none)
            Spacer()
            Text(value).foregroundColor(.gray)
        }
    }
    
    private func slotSetUp(slot: String, isAvailable: Bool) -> some View {
        HStack {
            Text(slot) // Display slot name (Morning / Evening)
                .fontWeight(.regular)
            
            Spacer()
            
            Text(isAvailable ? "Available" : "Not Available") // Show status
                .foregroundColor(isAvailable ? .green : .red)
                .fontWeight(.semibold)
        }
        .cornerRadius(8)
    }

    
    private func checkAvailability(for slot: String) -> Bool {
        let availableSlots: [String] = ["Morning"] // Example: Only Morning is available
        return availableSlots.contains(slot)
    }
    
    private func handleLogout() {
        isLoggedOut = true
    }

    
    
}

// ✅ Preview
#Preview {
    DoctorProfileView()
}
