import SwiftUI

// Doctor Profile Data Model

struct DoctorProfileView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    let doctor: Doctor
    
    @State private var doctorDetails: Doctor?
    @State private var departmentDetails: Department?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    profileRow(title: "Full Name", value: doctor.fullName)
                    if let department = departmentDetails {
                        profileRow(title: "Department", value: department.name)
                    }
                    profileRow(title: "Qualifications", value: doctor.qualifications)
                    profileRow(title: "Experience", value: "\(doctor.experience) years")
                    profileRow(title: "License Number", value: doctor.licenseNumber)
                    profileRow(title: "Gender", value: doctor.gender)
                }
                
                Section(header: Text("Contact Information")) {
                    profileRow(title: "Phone", value: doctor.phoneNumber)
                    profileRow(title: "Email", value: doctor.email)
                }
                
                if let department = departmentDetails {
                    Section(header: Text("Consultation Fee")) {
                        profileRow(title: "Fee", value: "₹\(String(format: "%.2f", department.fees))")
                    }
                }
            }
            .navigationTitle("Doctor Profile")
            .task {
                // Fetch doctor details
                if let departmentId = doctor.departmentId {
                    departmentDetails = await supabaseController.fetchDepartmentDetails(departmentId: departmentId)
                    
                }
            }
        }
    }
}
        
        // Reusable Profile Row Component
        private func profileRow(title: String, value: String) -> some View {
            HStack {
                Text(title).fontWeight(.none)
                Spacer()
                Text(value).foregroundColor(.gray)
            }
        }



