import SwiftUI

struct PatientView: View {
    @State private var searchText: String = ""
    
    var patientDetails: PatientDetails = PatientDetails(
        id: UUID(),
        blood_group: "O+",
        allergies: "None",
        existing_medical_record: "None",
        current_medication: "None",
        past_surgeries: "None",
        emergency_contact: "1234567899"
    )
    
    @State private var patients: [Patient] = [
        Patient(id: UUID(), fullName: "John Doe", gender: "Male", dateOfBirth: Date(), contactNo: "9876543210", email: "john@example.com"),
        Patient(id: UUID(), fullName: "Jane Smith", gender: "Female", dateOfBirth: Date(), contactNo: "9876543211", email: "jane@example.com"),
        Patient(id: UUID(), fullName: "Alice Johnson", gender: "Female", dateOfBirth: Date(), contactNo: "9876543212", email: "alice@example.com")
    ]
    
    private var filteredPatients: [Patient] {
        searchText.isEmpty
            ? patients
        : patients.filter { $0.fullname.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {  // 🔹 Tightens layout
                PatientSearchBar(text: $searchText)
                
                patientListView
            }
            .background(Color(.systemGray5).opacity(0.2))
            .navigationTitle("Patients")
            .navigationBarTitleDisplayMode(.inline) // 🔹 Keeps title compact
        }
    }
    
    private var patientListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPatients, id: \.id) { patient in
                    patientNavigationLink(patient)
                }
            }
            .padding(.top, 5)  // Small spacing before first card
        }
    }

    private func patientNavigationLink(_ patient: Patient) -> some View {
        NavigationLink(destination: PatientDetailView(patient: patient, patientDetails: patientDetails)) {
            PatientCard(patient: patient)
        }
    }
}

struct PatientSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search patients...", text: $text)
                .foregroundColor(.primary)
                .padding(8)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)  // Ensures it aligns with title
    }
}

// 🔹 Patient Card View
struct PatientCard: View {
    let patient: Patient
    
    var body: some View {
        HStack(spacing: 15) {
          
            VStack(alignment: .leading, spacing: 5) {
                Text(patient.fullname) // Fixed property name
                    .font(.headline)
                
                HStack {
                    Text("Gender: \(patient.gender)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("No: \(patient.contactno)") // 🔹 Fixed property name
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
//            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    PatientView()
}
