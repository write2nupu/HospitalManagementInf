//
//  PaymentView.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 26/03/25.
//


import SwiftUI

struct PaymentView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appointmentStore: AppointmentStore
    let appointment: Appointment
    @State private var invoice: Invoice
    
    @State private var selectedPaymentMethod: PaymentType
    @State private var showingConfirmation = false
    @State private var isProcessing = false
    
    enum PaymentType: String, Codable, CaseIterable {
        case applePay = "Apple Pay"
        case creditCard = "Credit/Debit Card"
        case upi = "UPI"
        case netBanking = "Net Banking"
    }
    
    enum PaymentStatus: String, Codable {
        case pending = "Pending"
        case paid = "Paid"
        case failed = "Failed"
    }
    
    init(appointment: Appointment) {
        self.appointment = appointment
        let newInvoice = Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: appointment.patient.id,
            amount: appointment.fee + 5,  // Service fee added
            paymentType: .upi,  // Default payment type
            status: .pending
        )
        self._invoice = State(initialValue: newInvoice)
        self._selectedPaymentMethod = State(initialValue: newInvoice.paymentType)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Payment")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                
                // Invoice Summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Invoice ID:")
                        Spacer()
                        Text(invoice.id.uuidString.prefix(8)) // Shortened ID
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Date Issued:")
                        Spacer()
                        Text(formattedDate(invoice.createdAt))
                    }
                    
                    HStack {
                        Text("Amount:")
                        Spacer()
                        Text("₹\(invoice.amount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                    }
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text(invoice.status.rawValue)
                            .foregroundColor(invoice.status == .paid ? .green : .red)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.mint.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Payment Method Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Payment Method")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack {
                        ForEach(PaymentType.allCases, id: \.self) { method in
                            HStack {
                                Text(method.rawValue)
                                Spacer()
                                if selectedPaymentMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.mint)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
                            .onTapGesture {
                                selectedPaymentMethod = method
                                invoice.paymentType = method
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Pay Button
                Button(action: processPayment) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Image(systemName: "lock.fill")
                            Text("Pay ₹\(invoice.amount)")
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isProcessing ? Color.gray : Color.mint)
                    .cornerRadius(10)
                }
                .disabled(isProcessing)
                .padding()
            }
        }
        .navigationBarItems(leading: Button("Cancel") {
            dismiss()
        })
        .alert("Payment Successful", isPresented: $showingConfirmation) {
            Button("OK") {
                finalizePayment()
            }
        } message: {
            Text("Your invoice has been marked as Paid.")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func processPayment() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            invoice.status = .paid
            showingConfirmation = true
        }
    }
    
    private func finalizePayment() {
        appointmentStore.addAppointment(appointment)
        dismiss()
    }
}
