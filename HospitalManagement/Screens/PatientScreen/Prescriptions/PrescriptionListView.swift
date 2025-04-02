import SwiftUI

struct PrescriptionListView: View {
    let prescriptions: [PrescriptionData]
    let doctorNames: [UUID: String]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(prescriptions, id: \.id) { prescription in
                    NavigationLink(destination: PrescriptionDetailView(prescription: prescription, doctorName: doctorNames[prescription.doctorId] ?? "Unknown Doctor")) {
                        PrescriptionRow(prescription: prescription, doctorName: doctorNames[prescription.doctorId] ?? "Unknown Doctor")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle("Prescriptions")
        .background(Color(.systemGroupedBackground))
    }
}

struct PrescriptionRow: View {
    let prescription: PrescriptionData
    let doctorName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "stethoscope.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dr. \(doctorName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(prescription.diagnosis)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            if let medicine = prescription.medicineName {
                Divider()
                
                HStack(spacing: 16) {
                    PrescriptionInfoBadge(
                        icon: "pills.fill",
                        text: medicine
                    )
                    
                    if let dosage = prescription.medicineDosage {
                        PrescriptionInfoBadge(
                            icon: "clock.fill",
                            text: dosage.rawValue
                        )
                    }
                }
            }
            
            if let tests = prescription.labTests, !tests.isEmpty {
                Text("Lab Tests Required")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct PrescriptionInfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct PrescriptionStatusBadge: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(status)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "completed":
            return .blue
        case "expired":
            return .red
        default:
            return .gray
        }
    }
} 