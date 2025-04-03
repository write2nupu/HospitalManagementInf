import SwiftUI

struct MedicalRecordsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink(destination: LabReportsView()) {
                    RecordCard(
                        icon: "cross.case.fill",
                        title: "Lab Reports",
                        subtitle: "View your lab test reports"
                    )
                }
                
                NavigationLink(destination: PrescriptionLabTestView()) {
                    RecordCard(
                        icon: "pills.fill",
                        title: "Prescriptions",
                        subtitle: "View your prescriptions"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Medical Records")
        .background(Color(.systemGroupedBackground))
    }
}

struct RecordCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.mint)
                .frame(width: 50, height: 50)
                .background(Color.mint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        MedicalRecordsView()
    }
} 