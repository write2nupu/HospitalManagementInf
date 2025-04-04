//
//  AllPaymentsView.swift
//  HospitalManagement
//
//  Created by sudhanshu on 25/03/25.
//

import SwiftUI

struct AllPaymentsView: View {
    @State private var invoices: [Invoice]
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @StateObject private var supabaseController = SupabaseController()
    @State private var hospitalId: UUID?
    @State private var selectedFilter: PaymentType?
    let patientNames: [UUID: String]
    
    init(invoices: [Invoice] = [], patientNames: [UUID: String]) {
        _invoices = State(initialValue: invoices)
        self.patientNames = patientNames
    }
    
    // Simplified computed property with intermediate variables
    var filteredInvoices: [Invoice] {
        // First filter paid invoices
        let paidInvoices = invoices.filter { $0.status == .paid }
        
        // Then apply type filter if needed
        if let filter = selectedFilter {
            return paidInvoices.filter { $0.paymentType == filter }
        }
        return paidInvoices
    }
    
    // Sort invoices separately to avoid complex chained expressions
    var sortedFilteredInvoices: [Invoice] {
        return filteredInvoices.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading payments...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack {
                    Text("Error")
                        .font(.title)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if invoices.isEmpty {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    Text("No payment records found")
                        .font(.headline)
                    Text("Any payments made will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Use pre-sorted and filtered data
                    ForEach(sortedFilteredInvoices) { invoice in
                        PaymentTableCell(
                            invoice: invoice,
                            patientName: patientNames[invoice.patientid]
                        )
                        .listRowInsets(EdgeInsets()) 
                        .listRowSeparator(.visible)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("All Payments")
        .navigationBarTitleDisplayMode(.inline)
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
        .task {
            if invoices.isEmpty {
                await loadHospitalId()
            }
        }
    }
    
    // Split the complex loadHospitalId logic
    private func loadHospitalId() async {
        isLoading = true
        errorMessage = nil
        
        // Get hospital ID from UserDefaults (stored during login)
        if let hospitalIdString = UserDefaults.standard.string(forKey: "hospitalId"),
           let hospitalId = UUID(uuidString: hospitalIdString) {
            print("Retrieved hospital ID from UserDefaults: \(hospitalId)")
            
            DispatchQueue.main.async {
                self.hospitalId = hospitalId
                self.loadInvoices()
            }
        } else {
            // Fallback to old method if no hospital ID in UserDefaults
            do {
                let result = try await supabaseController.fetchHospitalAndAdmin()
                handleHospitalResult(result)
            } catch {
                handleError(error)
            }
        }
    }
    
    private func handleHospitalResult(_ result: (Hospital, String)?) {
        if let (hospital, _) = result {
            hospitalId = hospital.id
            loadInvoices()
        } else {
            DispatchQueue.main.async {
                isLoading = false
                errorMessage = "No hospital information found."
            }
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            isLoading = false
            errorMessage = "Failed to load hospital: \(error.localizedDescription)"
        }
    }
    
    private func loadInvoices() {
        guard let id = hospitalId else {
            isLoading = false
            errorMessage = "No hospital selected. Please select a hospital first."
            return
        }
        
        Task {
            await fetchInvoicesForHospital(id)
        }
    }
    
    private func fetchInvoicesForHospital(_ id: UUID) async {
        do {
            let fetchedInvoices = try await supabaseController.fetchInvoices(HospitalId: id)
            DispatchQueue.main.async {
                invoices = fetchedInvoices
                isLoading = false
            }
        } catch {
            handleInvoiceError(error)
        }
    }
    
    private func handleInvoiceError(_ error: Error) {
        DispatchQueue.main.async {
            isLoading = false
            errorMessage = "Failed to load payments: \(error.localizedDescription)"
        }
    }
}

struct PaymentTableCell: View {
    let invoice: Invoice
    let patientName: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Left side - Name and Payment Type
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(patientName ?? "Loading...") - \(invoice.paymentType.rawValue.capitalized)")
                        .font(.system(size: 17, weight: .regular))
                    Text(invoice.createdAt, formatter: dateFormatter2)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Right side - Amount and Status
                HStack(spacing: 8) {
                    Text("₹\(String(format: "%.2f", Double(invoice.amount)))")
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

private let dateFormatter2: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy 'at' hh:mm a"
    return formatter
}()


