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
    var languagesSpoken: [String]
    var profileImage: String? // Store image URL or asset name
}


struct DoctorProfileView: View {
    @State var doctor: Doctor = Doctor(
        name: "Dr. Anubhav Dubey",
        specialization: "Cardiologist",
        qualifications: "MBBS, MD",
        experience: 10,
        hospitalAffiliations: ["Apollo", "Fortis"],
        consultationFee: 500.0,
        phoneNumber: "9876543210",
        email: "doctor@example.com",
        availableSlots: ["Monday: 10AM - 12PM", "Wednesday: 2PM - 4PM"],
        languagesSpoken: ["English", "Hindi"]
    )
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                Section(header: Text("Consultation Fee")) {
                    profileRow(title: "Fee", value: "₹\(String(format: "%.2f", doctor.consultationFee))")
                }
                
                Section(header: Text("Available Slots")) {
                    ForEach(doctor.availableSlots, id: \.self) { slot in
                        Text(slot)
                    }
                }
                
                Section(header: Text("Languages Spoken")) {
                    ForEach(doctor.languagesSpoken, id: \.self) { language in
                        Text(language)
                    }
                }
            }
            .navigationTitle("Doctor Profile")
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
}

// ✅ Preview
#Preview {
    DoctorProfileView()
}
