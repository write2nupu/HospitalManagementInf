import SwiftUI

struct PrescriptionListView: View {
    let prescriptions: [PrescriptionData]
    let doctorNames: [UUID: String]
    
    var body: some View {
        List(prescriptions, id: \.id) { prescription in
            NavigationLink(destination: PrescriptionDetailView(prescription: prescription, doctorName: doctorNames[prescription.doctorId] ?? "Unknown Doctor")) {
                PrescriptionRow(prescription: prescription, doctorName: doctorNames[prescription.doctorId] ?? "Unknown Doctor")
            }
        }
        .navigationTitle("Prescriptions")
        .listStyle(InsetGroupedListStyle())
    }
}

struct PrescriptionRow: View {
    let prescription: PrescriptionData
    let doctorName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dr. \(doctorName)")
                .font(.headline)
            
            Text(prescription.diagnosis)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 