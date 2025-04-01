import SwiftUI

struct PatientView: View {
    @State private var searchText: String = ""
    
    var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
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
        VStack(spacing: 8) {
            // Header and Search
            VStack(spacing: 8) {
                PatientSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.bottom, 3)
            }
            .background(Color.white)
            .shadow(color: AppConfig.shadowColor, radius: 2, x: 0, y: 2)
            .zIndex(1) // Keeps the search bar on top
            
            // Scrollable Content
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(filteredPatients, id: \.id) { patient in
                        patientNavigationLink(patient)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGray6).opacity(0.2))
        .ignoresSafeArea(.all, edges: .bottom)
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
                .font(.subheadline) // 🔹 Reduced font size
                .padding(6) // 🔹 Decreased padding
        }
        .padding(8) // 🔹 Reduced overall height
        .background(Color(.systemGray6))
        .cornerRadius(8) // 🔹 Slightly reduced corner radius
    }
}


// 🔹 Patient Card View
struct PatientCard: View {
    let patient: Patient
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(patient.fullname)
                    .font(.headline)
                
                HStack {
                    Text("Gender: \(patient.gender)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("No: \(patient.contactno)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(AppConfig.backgroundColor)
        .cornerRadius(12)
        .shadow(color: AppConfig.shadowColor, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    PatientView()
}
