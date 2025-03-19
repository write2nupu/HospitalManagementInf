import SwiftUI

struct DoctorProfileForPatient: View {
    var doctor: Doctor

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                
                // Profile Image & Name
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.mint)
                    
                    Text(doctor.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(doctor.specialization)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.mint.opacity(0.1))
                .cornerRadius(15)
                .shadow(color: .mint.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Details Section
                VStack(spacing: 10) {
                    profileCard(title: "Qualifications", value: doctor.qualifications)
                    profileCard(title: "Experience", value: "\(doctor.experience) years")
                    profileCard(title: "Consultation Fee", value: "₹\(String(format: "%.2f", doctor.consultationFee))")
                }

                // Info Sections (Aligned for Consistency)
                infoSection(title: "Hospital Affiliations", items: doctor.hospitalAffiliations)
                infoSection(title: "Available Slots", items: doctor.availableSlots)
                infoSection(title: "Languages Spoken", items: doctor.languagesSpoken)
            }
            .padding()
        }
        .navigationTitle("Doctor Profile")
        .background(Color.mint.opacity(0.05))
    }
    
    // MARK: - Reusable Card Design
    private func profileCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.mint)
            
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 70) // Ensures consistent height
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Reusable Info Section
    private func infoSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.mint)
            
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70) // Consistent height for all sections
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// ✅ Preview
#Preview {
    DoctorProfileForPatient(doctor: doctors[0])
}
