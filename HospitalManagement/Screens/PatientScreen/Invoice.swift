//
//  Invoice.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 26/03/25.
//

import SwiftUI

struct InvoiceListView: View {
    @State private var invoices: [Invoice] = [
        Invoice(id: UUID(), createdAt: Date(), patientid: UUID(), amount: 599, paymentType: .appointment, status: .paid, hospitalId: UUID()),
        Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-86400), patientid: UUID(), amount: 499, paymentType: .labTest, status: .paid, hospitalId: UUID()),
        Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-172800), patientid: UUID(), amount: 699, paymentType: .bed, status: .paid, hospitalId: UUID()),
        Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-259200), patientid: UUID(), amount: 999, paymentType: .appointment, status: .paid, hospitalId: UUID())
    ]
    
    @State private var selectedFilter: PaymentType? = nil
    
    var filteredInvoices: [Invoice] {
        invoices.filter { invoice in
            selectedFilter == nil || invoice.paymentType == selectedFilter
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredInvoices) { invoice in
                NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                    InvoiceRow(invoice: invoice)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All", action: { selectedFilter = nil })
                        ForEach(PaymentType.allCases, id: \.self) { type in
                            Button(type.rawValue.capitalized, action: { selectedFilter = type })
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// MARK: - Invoice Row
struct InvoiceRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(invoice.paymentType.rawValue.capitalized)
                    .font(.headline)
                
                Text("\(formatDate(invoice.createdAt)) #\(invoice.id.uuidString.prefix(8))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("₹ \(invoice.amount)")
                .font(.headline)
                .foregroundColor(.mint)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Helper Function
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy"
    return formatter.string(from: date)
}

// MARK: - Preview
struct InvoiceListView_Previews: PreviewProvider {
    static var previews: some View {
        InvoiceListView()
    }
}
