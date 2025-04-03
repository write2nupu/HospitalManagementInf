//
//  BedPaymentView.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 26/03/25.
//

import SwiftUI

// MARK: - Booking Summary View
struct BookingSummaryView: View {
    let hospital: Hospital
    let bed: Bed
    let bedBooking: BedBooking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Summary")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.buttonColor)
            
            VStack(spacing: 12) {
                summaryRow(title: "Hospital", value: hospital.name)
                summaryRow(title: "Bed Type", value: bed.type.rawValue)
                summaryRow(title: "Check In", value: formatDate(bedBooking.startDate))
                summaryRow(title: "Check Out", value: formatDate(bedBooking.endDate))
                
                Divider()
                
                HStack {
                    Text("Total Amount")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("₹\(bed.price)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.buttonColor)
                }
            }
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color:AppConfig.shadowColor ,radius: 2)
    }
    
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Payment Methods View
struct PaymentMethodsView: View {
    @Binding var selectedPaymentMethod: PaymentOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.buttonColor)
            
            ForEach(PaymentOption.allCases, id: \.self) { method in
                PaymentMethodRow(
                    isSelected: selectedPaymentMethod == method,
                    method: method,
                    action: { selectedPaymentMethod = method }
                )
            }
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color:AppConfig.shadowColor ,radius: 2)
    }
}

// MARK: - Payment Details View
struct PaymentDetailsView: View {
    let paymentMethod: PaymentOption
    @Binding var cardNumber: String
    @Binding var expiryDate: String
    @Binding var cvv: String
    @Binding var upiId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Details")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.buttonColor)
            
            if paymentMethod == .card {
                CustomTextField(text: $cardNumber, placeholder: "Card Number", keyboardType: .numberPad)
                HStack {
                    CustomTextField(text: $expiryDate, placeholder: "MM/YY", keyboardType: .numberPad)
                    CustomTextField(text: $cvv, placeholder: "CVV", keyboardType: .numberPad, isSecure: true)
                }
            } else if paymentMethod == .upi {
                CustomTextField(text: $upiId, placeholder: "Enter UPI ID")
            }
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color:AppConfig.shadowColor ,radius: 2)
    }
}

// MARK: - Main View
struct BedPaymentView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabaseController = SupabaseController()
    let bedBooking: BedBooking
    let bed: Bed
    let hospital: Hospital
    let onPaymentSuccess: (Invoice) -> Void
    
    @State private var selectedPaymentMethod: PaymentOption = .applePay
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var upiId = ""
    @State private var showingConfirmation = false
    @State private var isProcessingPayment = false
    @State private var errorMessage: String?
    @State private var currentInvoice: Invoice?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    BookingSummaryView(
                        hospital: hospital,
                        bed: bed,
                        bedBooking: bedBooking
                    )
                    
                    PaymentMethodsView(selectedPaymentMethod: $selectedPaymentMethod)
                    
                    if selectedPaymentMethod != .applePay {
                        PaymentDetailsView(
                            paymentMethod: selectedPaymentMethod,
                            cardNumber: $cardNumber,
                            expiryDate: $expiryDate,
                            cvv: $cvv,
                            upiId: $upiId
                        )
                    }
                }
                .padding()
            }
            
            VStack(spacing: 0) {
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Divider()
                paymentButton
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !isProcessingPayment {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .interactiveDismissDisabled(isProcessingPayment)
        .overlay {
            if isProcessingPayment {
                processingOverlay
            }
        }
        .sheet(isPresented: $showingConfirmation) {
            if let invoice = currentInvoice {
                NavigationStack {
                    BedPaymentConfirmationView(
                        bedBooking: bedBooking,
                        hospital: hospital,
                        invoice: invoice
                    )
                }
            }
        }
    }
    
    private var processingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Processing Payment...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
    }
    
    private var paymentButton: some View {
        Button(action:{
                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                    generator.impactOccurred()
                    
                    processPayment()
                }) {
            if isProcessingPayment {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Pay ₹\(bed.price)")
                    .fontWeight(.semibold)
            }
        }
                .foregroundColor(AppConfig.cardColor)
        .frame(maxWidth: .infinity)
        .padding()
        .background(isProcessingPayment ? Color.gray : AppConfig.buttonColor)
        .cornerRadius(12)
        .padding()
        .disabled(isProcessingPayment || !isValidPaymentDetails())
    }
    
    private func isValidPaymentDetails() -> Bool {
        switch selectedPaymentMethod {
        case .applePay:
            return true
        case .card:
            return !cardNumber.isEmpty && !expiryDate.isEmpty && !cvv.isEmpty
        case .upi:
            return !upiId.isEmpty
        }
    }
    
    private func createInvoice() -> Invoice {
        Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: bedBooking.patientId,
            amount: bed.price,
            paymentType: .bed,
            status: .paid,
            hospitalId: hospital.id
        )
    }
    
    private func processPayment() {
        isProcessingPayment = true
        errorMessage = nil
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            do {
                let invoice = createInvoice()
                currentInvoice = invoice
                // Call the success callback
                onPaymentSuccess(invoice)
                isProcessingPayment = false
                showingConfirmation = true
            }
        }
    }
}

// MARK: - Supporting Views
struct PaymentMethodRow: View {
    let isSelected: Bool
    let method: PaymentOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.icon)
                    .foregroundColor(AppConfig.buttonColor)
                Text(method.title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppConfig.approvedColor)
                }
            }
            .padding()
            .background(AppConfig.buttonColor.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .textFieldStyle(.plain)
        .padding()
        .background(AppConfig.buttonColor.opacity(0.1))
        .cornerRadius(8)
        .keyboardType(keyboardType)
    }
}

// MARK: - Extensions
extension PaymentOption {
    static var allCases: [PaymentOption] = [.applePay, .card, .upi]
    
    var title: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .card: return "Credit/Debit Card"
        case .upi: return "UPI"
        }
    }
    
    var icon: String {
        switch self {
        case .applePay: return "applelogo"
        case .card: return "creditcard"
        case .upi: return "indianrupeesign"
        }
    }
}

// MARK: - Preview
struct BedPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleHospital = Hospital(
            id: UUID(),
            name: "Apollo Hospital",
            address: "123, Green Street",
            city: "New Delhi",
            state: "Delhi",
            pincode: "110001",
            mobile_number: "9876543210",
            email: "contact@apollo.com",
            license_number: "HOSP12345",
            is_active: true,
            assigned_admin_id: nil
        )

        let sampleBed = Bed(
            id: UUID(),
            hospitalId: sampleHospital.id,
            price: 5000,
            type: .ICU,
            isAvailable: true
        )

        let sampleBedBooking = BedBooking(
            id: UUID(),
            patientId: UUID(),
            hospitalId: sampleHospital.id,
            bedId: sampleBed.id,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            isAvailable: true
        )

        NavigationView {
            BedPaymentView(
                bedBooking: sampleBedBooking,
                bed: sampleBed,
                hospital: sampleHospital,
                onPaymentSuccess: { _ in }
            )
        }
    }
}
