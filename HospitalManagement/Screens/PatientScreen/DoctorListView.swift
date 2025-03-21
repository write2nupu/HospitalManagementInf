import SwiftUI

struct DoctorListView: View {
    let doctors: [Doctor]
    @State private var selectedDoctor: Doctor?  // For modal presentation
    @StateObject private var supabaseController = SupabaseController()
    @State private var departmentDetails: [UUID: Department] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(doctors) { doctor in
                    Button(action: {
                        selectedDoctor = doctor
                    }) {
                        doctorCard(doctor: doctor)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select Doctor")
        .background(Color.mint.opacity(0.05))
        
        // ✅ Modal Presentation for Doctor Profile
        .sheet(item: $selectedDoctor) { doctor in
            DoctorProfileForPatient(doctor: doctor)
        }
        .task {
            // Fetch department details for each doctor
            for doctor in doctors {
                if let departmentId = doctor.departmentId {
                    if let department = await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
                        departmentDetails[departmentId] = department
                    }
                }
            }
        }
    }

    // MARK: - Doctor Card UI
    private func doctorCard(doctor: Doctor) -> some View {
        HStack(spacing: 15) {
            Image(systemName: "person.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.mint)
                .background(Color.mint.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(doctor.fullName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let departmentId = doctor.departmentId,
                   let department = departmentDetails[departmentId] {
                    Text(department.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("₹\(Int(department.fees))")
                        .font(.body)
                        .foregroundColor(.mint)
                } else {
                    Text("Department not assigned")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .mint.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
