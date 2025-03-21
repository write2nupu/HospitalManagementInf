import SwiftUI

// MARK: - Patient Dashboard View
struct PatientDashboard: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @State private var patient: Patient
    
    init(patient: Patient) {
        _patient = State(initialValue: patient)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Patient Info Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Welcome, \(patient.fullName)")
                        .font(.title)
                        .padding()
                    
                    PatientInfoCard(patient: patient)
                }// Quick Actions
                ////                ScrollView {
                ////                    LazyVGrid(columns: [
                ////                        GridItem(.flexible()),
                ////                        GridItem(.flexible())
                ////                    ], spacing: 20) {
                ////                        NavigationLink(destination: AppointmentView(patient: patient)) {
                ////                            DashboardCard(title: "Book Appointment",
                ////                                        systemImage: "calendar.badge.plus")
                ////                        }
                ////
                ////                        NavigationLink(destination: MedicalHistoryView(patient: patient)) {
                ////                            DashboardCard(title: "Medical History",
                ////                                        systemImage: "list.clipboard")
                ////                        }
                ////
                ////                        NavigationLink(destination: ProfileView(patient: $patient)) {
                ////                            DashboardCard(title: "Profile",
                ////                                        systemImage: "person.circle")
                ////                        }
                ////
                ////                        NavigationLink(destination: EmergencyContactView(patient: patient)) {
                ////                            DashboardCard(title: "Emergency Contacts",
                ////                                        systemImage: "phone.circle")
                ////                        }
                //                    }
                //                    .padding()
                //                }
                //            }
                //            .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    struct PatientInfoCard: View {
        let patient: Patient
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Patient ID: \(patient.id)")
                Text("Phone: \(patient.phoneNumber)")
                Text("Email: \(patient.email)")
                if let details = patient.detailId {
                    Text("Blood Group: \(details)")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    struct DashboardCard: View {
        let title: String
        let systemImage: String
        
        var body: some View {
            VStack {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Editable Section Component
    struct EditableSection<Content: View>: View {
        let title: String
        @Binding var isEditing: Bool
        let content: Content
        
        init(title: String, isEditing: Binding<Bool>, @ViewBuilder content: () -> Content) {
            self.title = title
            self._isEditing = isEditing
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                Divider().background(Color.mint)
                content
            }
            .padding()
            .background(Color.mint.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Editable Info Row
    struct EditableInfoRow: View {
        let title: String
        @Binding var value: String
        
        var body: some View {
            HStack {
                Text("\(title):")
                    .fontWeight(.semibold)
                    .foregroundColor(.mint)
                Spacer()
                TextField(title, text: $value)
                    .multilineTextAlignment(.trailing)
                    .disabled(false)
            }
            .padding(.vertical, 4)
        }

    }
    
}

