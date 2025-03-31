import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Picture Placeholder
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                )
                .padding(.top, 20)
            
            Text(patient.fullname)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                InfoRowPatinetList(label: "Gender", value: patient.gender)
                InfoRowPatinetList(label: "Date of Birth", value: formatDate(patient.dateofbirth))
                InfoRowPatinetList(label: "Contact", value: patient.contactno)
                InfoRowPatinetList(label: "Email", value: patient.email)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Patient Details")
        .background(Color(.systemGray5).opacity(0.2).edgesIgnoringSafeArea(.all))
    }
    
    // Helper function to format Date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// InfoRow View
struct InfoRowPatinetList: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}
