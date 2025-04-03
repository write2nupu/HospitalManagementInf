import SwiftUI

struct DoctorProfileForPatient: View {
    let doctor: Doctor
    @StateObject private var supabaseController = SupabaseController()
    @State private var departmentDetails: Department?
    @State private var hospitalAffiliations: [String] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.mint)
                            .background(Circle().fill(Color.mint.opacity(0.1)))
                        
                        VStack(spacing: 4) {
                            Text(doctor.full_name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let department = departmentDetails {
                                Text(department.name)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            
                            StatusBadge(isActive: doctor.is_active)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.mint.opacity(0.1))
                    .cornerRadius(15)
                    
                    // Professional Information
                    InfoSection(title: "Professional Information") {
                        InfoRow4(icon: "book.fill", title: "Qualifications", value: doctor.qualifications)
                        InfoRow4(icon: "clock.fill", title: "Experience", value: "\(doctor.experience) years")
                        if let department = departmentDetails {
                            InfoRow4(icon: "indianrupeesign", title: "Consultation Fee", value: String(format: "₹%.2f", department.fees))
                        }
                        InfoRow4(icon: "creditcard.fill", title: "License Number", value: doctor.license_num)
                    }
                    
                    // Contact Information
                    InfoSection(title: "Contact Information") {
                        InfoRow4(icon: "phone.fill", title: "Phone", value: doctor.phone_num)
                        InfoRow4(icon: "envelope.fill", title: "Email", value: doctor.email_address)
                    }
                    
                    // Hospital Affiliations
                    if !hospitalAffiliations.isEmpty {
                        InfoSection(title: "Hospital Affiliations") {
                            ForEach(hospitalAffiliations, id: \.self) { hospital in
                                InfoRow4(icon: "building.2.fill", title: "Hospital", value: hospital)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.mint.opacity(0.1))
                .cornerRadius(15)
                .shadow(color: .mint.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Details Section
                VStack(spacing: 10) {
//                    profileCard(title: "Qualifications", value: doctor.qualifications)
//                    profileCard(title: "Experience", value: "\(doctor.experience) years")
//                    profileCard(title: "Consultation Fee", value: "₹\(String(format: "%.2f", doctor.consultationFee))")
                }

                // Info Sections (Aligned for Consistency)
//                infoSection(title: "Hospital Affiliations", items: doctor.hospitalAffiliations)
//                infoSection(title: "Available Slots", items: doctor.availableSlots)
//                infoSection(title: "Languages Spoken", items: doctor.languagesSpoken!)

            }
        }
        .navigationTitle("Doctor Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDoctorDetails()
        }
    }
    
    private func loadDoctorDetails() async {
        isLoading = true
        
        // Fetch department details
        if let departmentId = doctor.department_id {
            departmentDetails = await supabaseController.fetchDepartmentDetails(departmentId: departmentId)
        }
        
        // Fetch hospital affiliations
        if let hospitalId = doctor.hospital_id {
            hospitalAffiliations = await supabaseController.fetchHospitalAffiliations(doctorId: hospitalId)
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views
private struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .mint.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InfoRow4: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.mint)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}



