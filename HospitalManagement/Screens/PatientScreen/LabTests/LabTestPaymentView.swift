import SwiftUI
import Foundation

struct LabTestPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseController()
    
    let amount: Double
    let selectedTests: [LabTest.LabTestName]
    let preferredDate: Date
    let prescriptionId: UUID
    let onComplete: (Bool) -> Void
    
    @State private var selectedPaymentMethod: PaymentOption = .upi
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private func createBookingAndInvoice() async {
        isLoading = true
        do {
            print("📋 Creating lab test booking and invoice...")
            print("- Selected Tests: \(selectedTests.map { $0.rawValue })")
            print("- Date: \(preferredDate)")
            print("- Amount: ₹\(amount)")
            
            guard let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
                  let patientId = UUID(uuidString: patientIdString),
                  let hospitalIdString = UserDefaults.standard.string(forKey: "selectedHospitalId"),
                  let hospitalId = UUID(uuidString: hospitalIdString) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing patient or hospital ID"])
            }
            
            // First create the booking
            print("📝 Creating lab test booking...")
            try await supabase.bookLabTest(
                tests: selectedTests,
                prescriptionId: prescriptionId,
                testDate: preferredDate,
                paymentMethod: selectedPaymentMethod,
                hospitalId: hospitalId
            )
            print("✅ Lab test booking created successfully!")
            
            // Create invoice in Supabase
            print("💰 Creating invoice record...")
            let invoiceId = UUID()
            try await supabase.client.from("Invoice")
                .insert([
                    "id": invoiceId.uuidString,
                    "patientid": patientId.uuidString,
                    "hospitalId": hospitalId.uuidString,
                    "amount": String(Int(amount)),
                    "paymentType": "labTest",
                    "status": "paid",
                    "createdAt": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            print("✅ Invoice created successfully!")
            
            await MainActor.run {
                isLoading = false
                onComplete(true)
                dismiss()
            }
        } catch {
            print("❌ Error during process: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Payment Summary Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Payment Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        ForEach(selectedTests, id: \.self) { test in
                            HStack {
                                Text(test.rawValue)
                                Spacer()
                                Text("₹\(Int(test.price))")
                            }
                            .font(.body)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack {
                            Text("Total Amount")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("₹\(Int(amount))")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                
                // Payment Methods Section (Dummy)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Payment Method")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        ForEach(PaymentOption.allCases, id: \.self) { method in
                            HStack {
                                Image(systemName: method == .upi ? "qrcode" : 
                                                method == .card ? "creditcard" : "network")
                                    .font(.system(size: 24))
                                    .foregroundColor(.mint)
                                Text(method.rawValue)
                                    .font(.body)
                                Spacer()
                                if method == selectedPaymentMethod {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.mint)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .onTapGesture {
                                selectedPaymentMethod = method
                            }
                        }
                    }
                }
                
                // Pay Button
                Button(action: {
                    Task {
                        await createBookingAndInvoice()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Pay ₹\(Int(amount))")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.mint)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading)
            }
            .padding()
        }
        .navigationTitle("Payment")
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
}

//#Preview {
//    LabTestPaymentView(
//        amount: 1500,
//        selectedTests: [.completeBloodCount, .bloodSugarTest],
//        preferredDate: Date(),
//        prescriptionId: UUID(),
//        onComplete: { _ in }
//    )
//}
