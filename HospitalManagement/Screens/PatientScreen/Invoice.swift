//
//  Invoice.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 26/03/25.
//

import SwiftUI

struct InvoiceListView: View {
    @State private var invoices: [Invoice] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var selectedFilter: PaymentType? = nil
    @StateObject private var supabaseController = SupabaseController()
    
    // Optional: If you want to filter by a specific patient ID
    var patientId: UUID? = nil
    
    var filteredInvoices: [Invoice] {
        invoices.filter { invoice in
            selectedFilter == nil || invoice.paymentType == selectedFilter
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Invoices")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
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
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                if isLoading {
                    ProgressView("Loading invoices...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            Task {
                                await fetchInvoices()
                            }
                        }
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .padding()
                } else if invoices.isEmpty {
                    VStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No invoices found")
                            .font(.headline)
                        
                        Text("Your invoice history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredInvoices.sorted(by: { $0.createdAt > $1.createdAt })) { invoice in
                                NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                    InvoiceRow(invoice: invoice)
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .padding(.horizontal)
                            }
                            
                            // Add extra space at the bottom to ensure content doesn't go under tab bar
                            Color.clear.frame(height: 60)
                        }
                        .background(Color(.systemBackground))
                    }
                    .refreshable {
                        // Create a temporary array to hold data during refresh
                        let tempInvoices = invoices
                        
                        // Start refresh with loading indicator
                        isLoading = true
                        
                        // Fetch invoices
                        if let patientId = patientId {
                            let newInvoices = await supabaseController.fetchInvoicesByPatientId(patientId: patientId)
                            
                            // Only update if we got data back
                            if !newInvoices.isEmpty {
                                invoices = newInvoices
                            } else if !tempInvoices.isEmpty {
                                // Keep existing data if refresh returned empty
                                invoices = tempInvoices
                            }
                        } else {
                            let newInvoices = await supabaseController.fetchAllInvoices()
                            
                            // Only update if we got data back
                            if !newInvoices.isEmpty {
                                invoices = newInvoices
                            } else if !tempInvoices.isEmpty {
                                // Keep existing data if refresh returned empty
                                invoices = tempInvoices 
                            }
                        }
                        
                        isLoading = false
                    }
                }
            }
            .padding(.top)
        }
        .task {
            if invoices.isEmpty {
                await fetchInvoices()
            }
        }
    }
    
    func fetchInvoices() async {
        isLoading = true
        errorMessage = nil
        
        if let patientId = patientId {
            // Fetch invoices for a specific patient
            let fetchedInvoices = await supabaseController.fetchInvoicesByPatientId(patientId: patientId)
            if !fetchedInvoices.isEmpty {
                invoices = fetchedInvoices
            } else if invoices.isEmpty {
                // Only show empty state if we have no existing data
                errorMessage = "Unable to load invoices. Please try again later."
            }
        } else {
            // Fetch all invoices
            let fetchedInvoices = await supabaseController.fetchAllInvoices()
            if !fetchedInvoices.isEmpty {
                invoices = fetchedInvoices
            } else if invoices.isEmpty {
                // Only show empty state if we have no existing data
                errorMessage = "Unable to load invoices. Please try again later."
            }
        }
        
        isLoading = false
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
            
            HStack {
                Text("₹ \(invoice.amount)")
                    .font(.headline)
                    .foregroundColor(.mint)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
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
