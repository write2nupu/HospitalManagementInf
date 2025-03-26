//
//  AllPaymentsView.swift
//  HospitalManagement
//
//  Created by sudhanshu on 25/03/25.
//

import SwiftUI

struct AllPaymentsView: View {
    let invoices: [Invoice]
    @State private var selectedFilter: PaymentType?
    
    var filteredInvoices: [Invoice] {
        if let filter = selectedFilter {
            return invoices.filter { $0.paymentType == filter }
        }
        return invoices
    }
    
    var body: some View {
        List {
            ForEach(filteredInvoices.sorted(by: { $0.createdAt > $1.createdAt })) { invoice in
                PaymentTableCell(invoice: invoice)
                    .listRowInsets(EdgeInsets()) // Remove default list row padding
                    .listRowSeparator(.visible) // Add separator between rows
            }
        }
        .listStyle(PlainListStyle()) // Use plain style to match the design
        .navigationTitle("All Payments")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { selectedFilter = nil }) {
                        Label("All Payments", systemImage: "list.bullet")
                    }
                    
                    Button(action: { selectedFilter = .appointment }) {
                        Label("Consultations", systemImage: "person.fill")
                    }
                    
                    Button(action: { selectedFilter = .bed }) {
                        Label("Bed Charges", systemImage: "bed.double.fill")
                    }
                    
                    Button(action: { selectedFilter = .labTest }) {
                        Label("Lab Tests", systemImage: "cross.case.fill")
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

struct PaymentTableCell: View {
    let invoice: Invoice
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Left side - Name and Payment Type
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rahul - \(invoice.paymentType.rawValue.capitalized)")
                        .font(.system(size: 17, weight: .regular))
                    Text(invoice.createdAt, formatter: dateFormatter)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Right side - Amount and Status
                HStack(spacing: 8) {
                    Text("₹\(invoice.amount, specifier: "%.2f")")
                        .font(.system(size: 17, weight: .regular))
                    
                    // Paid Status Indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
    
                    
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy 'at' hh:mm a"
    return formatter
}()

struct AllPaymentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AllPaymentsView(invoices: [
                Invoice(id: UUID(), createdAt: Date(), patientid: UUID(), amount: 599, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-1800), patientid: UUID(), amount: 499, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-3600), patientid: UUID(), amount: 599, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-7200), patientid: UUID(), amount: 499, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-14400), patientid: UUID(), amount: 599, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-28800), patientid: UUID(), amount: 599, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-43200), patientid: UUID(), amount: 499, paymentType: .labTest, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-86400), patientid: UUID(), amount: 599, paymentType: .labTest, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-172800), patientid: UUID(), amount: 499, paymentType: .bed, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-259200), patientid: UUID(), amount: 599, paymentType: .bed, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-345600), patientid: UUID(), amount: 499, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-432000), patientid: UUID(), amount: 599, paymentType: .appointment, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-518400), patientid: UUID(), amount: 499, paymentType: .labTest, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-604800), patientid: UUID(), amount: 599, paymentType: .bed, status: .paid),
                Invoice(id: UUID(), createdAt: Date().addingTimeInterval(-691200), patientid: UUID(), amount: 499, paymentType: .appointment, status: .paid)
            ])
        }
    }
} 
