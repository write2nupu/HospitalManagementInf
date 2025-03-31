import SwiftUI

struct PatientView: View {
    @State private var searchText: String = ""
    
    // Dummy data for testing
    @State private var patients: [Patient] = [
        Patient(id: UUID(), fullName: "John Doe", gender: "Male", dateOfBirth: Date(), contactNo: "9876543210", email: "john@example.com"),
        Patient(id: UUID(), fullName: "Jane Smith", gender: "Female", dateOfBirth: Date(), contactNo: "9876543211", email: "jane@example.com"),
        Patient(id: UUID(), fullName: "Alice Johnson", gender: "Female", dateOfBirth: Date(), contactNo: "9876543212", email: "alice@example.com")
    ]
    
    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return patients
        } else {
            return patients.filter { $0.fullname.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Custom Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search patients...", text: $searchText)
                        .foregroundColor(.primary)
                        .padding(8)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // Patient List with Cards
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPatients) { patient in
                            NavigationLink(destination: PatientDetailView(patient: patient)) {
                                HStack(spacing: 15) {
                                    // Profile Image Placeholder
                                    Circle()
                                        .fill(Color.blue.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                                .foregroundColor(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(patient.fullName)
                                            .font(.headline)
                                        HStack {
                                            Text("Gender: \(patient.gender)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text(patient.contactNo)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .background(Color(.systemGray5).opacity(0.2))
            .navigationTitle("Patients")
        }
    }
}
