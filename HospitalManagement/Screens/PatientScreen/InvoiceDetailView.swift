//
//  InvoiceDetailView.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 26/03/25.
//

import SwiftUI

struct InvoiceDetailView: View {
    let invoice: Invoice
    @State private var patientName: String = "Patient"
    @StateObject private var supabaseController = SupabaseController()
    @State private var isLoadingPatient: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Invoice Header
                VStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppConfig.buttonColor)
                    
                    Text("Invoice Details")
                        .font(.title2)
                        .bold()
                        .foregroundColor(AppConfig.buttonColor)
                }
                .padding(.top, 20)
                
                // Patient Information (if loaded)
                if !isLoadingPatient && patientName != "Patient" {
                    VStack(alignment: .leading, spacing: 15) {
                        DetailRow(icon: "person.fill", label: "Patient", value: patientName)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    .padding(.horizontal)
                }
                
                // Invoice Information Card
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "number", label: "Invoice ID", value: String(invoice.id.uuidString.prefix(8)))
                    DetailRow(icon: "calendar", label: "Date", value: formatDate(invoice.createdAt))
                    DetailRow(icon: "creditcard", label: "Payment Type", value: invoice.paymentType.rawValue.capitalized)
                    DetailRow(icon: invoice.status == .paid ? "checkmark.circle.fill" : "hourglass", label: "Status", value: invoice.status.rawValue.capitalized, color: invoice.status == .paid ? .green : .orange)
                    DetailRow(icon: "indianrupeesign.circle", label: "Amount", value: "₹ \(invoice.amount)", color: .white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)
                
                Spacer()
            
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPatientDetails()
        }
    }
    
    private func loadPatientDetails() async {
        isLoadingPatient = true
        
        do {
            // Fetch patient details using the patientid from the invoice
            let patients = await supabaseController.fetchPatients()
            if let patient = patients.first(where: { $0.id == invoice.patientid }) {
                patientName = patient.fullname
            }
        }        
        isLoadingPatient = false
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .white
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppConfig.buttonColor)
            
            Text(label + ":")
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .foregroundColor(color)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Preview
struct InvoiceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        InvoiceDetailView(invoice: Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: UUID(),
            amount: 599,
            paymentType: .appointment,
            status: .paid,
            hospitalId: UUID()
        ))
    }
}
