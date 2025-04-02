//
//  BillingView.swift
//  HospitalManagement
//
//  Created by sudhanshu on 25/03/25.
//
import SwiftUI
import Combine

struct BillingView: View {
    @State private var invoices: [Invoice] = []
    @State private var patientNames: [UUID: String] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAdminProfile = false
    @StateObject private var supabaseController = SupabaseController()
    @State private var hospitalId: UUID?
    
    // Break total calculation into a simpler function
    var totalRevenue: Double {
        return calculateRevenueForType(nil)
    }
    
    var consultantRevenue: Double {
        return calculateRevenueForType(.appointment)
    }
    
    var testRevenue: Double {
        return calculateRevenueForType(.labTest)
    }
    
    var bedRevenue: Double {
        return calculateRevenueForType(.bed)
    }
    
    // Helper function to calculate revenue based on type
    private func calculateRevenueForType(_ type: PaymentType?) -> Double {
        var total = 0.0
        for invoice in invoices {
            if type == nil || invoice.paymentType == type {
                total += Double(invoice.amount)
            }
        }
        return total
    }
    
    // Helper property for recent paid invoices - limit to 5
    private var recentPaidInvoices: [Invoice] {
        let paid = invoices.filter { $0.status == .paid }
        return paid.sorted { $0.createdAt > $1.createdAt }.prefix(5).map { $0 }
    }
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 20) {
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
                    .padding(.horizontal)
                    
                    // Revenue Breakdown Cards - Single column vertical layout
                    VStack(spacing: 16) {
                        RevenueCard(title: "Consultants", amount: consultantRevenue, color: .blue)
                        RevenueCard(title: "Tests", amount: testRevenue, color: .green)
                        RevenueCard(title: "Beds", amount: bedRevenue, color: .purple)
                    }
                    .padding(.horizontal)
                    
                    // Recent Payments Section Header
                    HStack {
                        Text("Recent Payments")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        navigationLinkToAllPayments
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Recent Payments List
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if invoices.isEmpty {
                        Text("No invoices found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Display payments directly in the VStack
                        ForEach(recentPaidInvoices) { invoice in
                            RecentPaymentRow(
                                invoice: invoice,
                                patientName: patientNames[invoice.patientid]
                            )
                            .padding(.horizontal)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .overlay(ProgressView())
            }
        }
        .navigationTitle("Billing")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .background(Color(.systemGray6).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdminProfile = true
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.mint)
                }
            }
        }
        .sheet(isPresented: $showAdminProfile) {
            AdminProfileView()
        }
        .task {
            // Load hospital ID first, then invoices
            await loadHospitalId()
        }
    }
    
    private var navigationLinkToAllPayments: some View {
        // Extract the paid invoices outside the closure
        let paidInvoices = invoices.filter { $0.status == .paid }
        
        return NavigationLink(destination: AllPaymentsView(invoices: paidInvoices, patientNames: patientNames)) {
            Text("See All")
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Data Loading Functions
    
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
                processHospitalResult(result)
            } catch {
                handleHospitalError(error)
            }
        }
    }
    
    private func processHospitalResult(_ result: (Hospital, String)?) {
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
    
    private func handleHospitalError(_ error: Error) {
        DispatchQueue.main.async {
            isLoading = false
            errorMessage = "Failed to load hospital: \(error.localizedDescription)"
        }
    }
    
    private func loadInvoices() {
        // Check if hospital ID is available
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
            
            // After fetching invoices, fetch patient names
            let patientIds = Set(fetchedInvoices.map { $0.patientid })
            let names = try await fetchPatientNames(for: Array(patientIds))
            
            DispatchQueue.main.async {
                invoices = fetchedInvoices
                patientNames = names
                isLoading = false
            }
        } catch {
            handleInvoiceError(error)
        }
    }
    
     func fetchPatientNames(for patientIds: [UUID]) async throws -> [UUID: String] {
        var names: [UUID: String] = [:]
        
        for patientId in patientIds {
            if let patient = try await supabaseController.fetchPatient(id: patientId) {
                names[patientId] = "\(patient.fullname)"
            }
        }
        
        return names
    }
    
    private func handleInvoiceError(_ error: Error) {
        DispatchQueue.main.async {
            isLoading = false
            errorMessage = "Failed to load invoices: \(error.localizedDescription)"
        }
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
    let patientName: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(patientName ?? "Loading...")
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
                Text("₹\(String(format: "%.2f", Double(invoice.amount)))")
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


// Helper extension for SupabaseController
extension SupabaseController {
    func fetchInvoices(HospitalId: UUID) async throws -> [Invoice] {
        do {
            let invoices: [Invoice] = try await client.from("Invoice")
                .select("*")
                .eq("hospitalId", value: HospitalId)  // Ensure field name matches exactly with database
                .execute()
                .value
            print(invoices)
            return invoices
        } catch {
            print("Error fetching invoices: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchPatient(id: UUID) async throws -> Patient? {
        let patients: [Patient] = try await client.from("Patient")
            .select("*")
            .eq("id", value: id)
            .execute()
            .value
        
        return patients.first
    }
}
