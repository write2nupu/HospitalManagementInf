//
//  BillingView.swift
//  HospitalManagement
//
//  Created by sudhanshu on 25/03/25.
//
import SwiftUI
import Combine

struct BillingView: View {
    @State private var invoices: [Invoice] = [
        Invoice(id: UUID(), createdAt: Date(), patientid: UUID(), amount: 2000, paymentType: .appointment, status: .paid),
        Invoice(id: UUID(), createdAt: Date(), patientid: UUID(), amount: 1500, paymentType: .labTest, status: .paid),
        Invoice(id: UUID(), createdAt: Date(), patientid: UUID(), amount: 3000, paymentType: .bed, status: .paid),
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
    ]
    
    var totalRevenue: Double {
        var total = 0.0
        for invoice in invoices {
            total += Double(invoice.amount)
        }
        return total
    }
    var consultantRevenue: Double {
        var total = 0.0
        for invoice in invoices {
            if invoice.paymentType == .appointment {
                total += Double(invoice.amount)
            }
        }
        return total
    }
    var testRevenue: Double {
        var total = 0.0
        for invoice in invoices {
            if invoice.paymentType == .labTest {
                total += Double(invoice.amount)
            }
        }
        return total
    }
    var bedRevenue: Double {
        var total = 0.0
        for invoice in invoices {
            if invoice.paymentType == .bed {
                total += Double(invoice.amount)
            }
        }
        return total
    }
    
    var body: some View {
        NavigationView {
                VStack(spacing: 20) {
                    // Revenue Overview Section
                    VStack(spacing: 16) {
                        // Total Revenue Card
                        VStack {
                            Text("Total Revenue")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("₹\(String(format: "%.2f", totalRevenue))")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8)

                        // Revenue Breakdown Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            RevenueCard(title: "Consultants", amount: consultantRevenue, color: .blue)
                            RevenueCard(title: "Tests", amount: testRevenue, color: .green)
                            RevenueCard(title: "Beds", amount: bedRevenue, color: .purple)
                        }
                    }
                    .padding(.horizontal)

                    // Recent Payments Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Payments")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                            NavigationLink(destination: AllPaymentsView(invoices: invoices.filter { $0.status == .paid })) {
                                Text("See All")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        // Table View for Recent Payments
                        List(invoices.filter { $0.status == .paid }.sorted(by: { $0.createdAt > $1.createdAt })) { invoice in
                                RecentPaymentRow(invoice: invoice)
                                    .listRowInsets(EdgeInsets()) // Remove default list row padding
                            }
                            .listStyle(PlainListStyle()) // Use plain list style
                            .frame(maxHeight: .infinity)
                        }
                   // .frame(height: 600) // Fixed height for scroll view
                    }
                }
                .padding(.top).navigationTitle("Billing").navigationBarTitleDisplayMode(.large)
                .background(Color(.systemGroupedBackground))
            }
            
            
    }


// Helper Views
struct RevenueCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("₹\(String(format: "%.2f", amount))")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

struct RecentPaymentRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rahul")
                    .font(.headline)
                Text(invoice.paymentType.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(invoice.createdAt, formatter: dateFormatter1)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(invoice.amount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("PAID")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(4)
            }
        }
        .padding()
    }
}

private let dateFormatter1: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
