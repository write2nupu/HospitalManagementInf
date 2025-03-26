//
//  BedPaymentView.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 26/03/25.
//

import SwiftUI

struct BedPaymentView: View {
    @Environment(\.dismiss) var dismiss
    let bedBooking: BedBooking
    let bed: Bed  // Now passing Bed separately
    let hospital: Hospital
    
    @State private var selectedPaymentMethod: PaymentOption = .applePay
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var upiId = ""
    @State private var showingConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("Make Payment")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                    .padding(.top)

                // Bed Booking Details
                bookingDetailsSection

                // Payment Methods
                paymentMethodsSection

                // Payment Input Fields (Only for Card & UPI)
                if selectedPaymentMethod != .applePay {
                    paymentFieldsSection
                }

                // Pay Button
                payButton
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationBarItems(leading: Button("Cancel") {
            dismiss()
        })
        .alert("Payment Successful", isPresented: $showingConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your bed booking payment has been successfully processed.")
        }
        .background(Color(UIColor.white).edgesIgnoringSafeArea(.all))
    }

    // MARK: - Booking Details Section
    private var bookingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Details")
                .font(.headline)
                .foregroundColor(.mint)

            HStack {
                Text("Hospital:")
                Spacer()
                Text(hospital.name)
                    .fontWeight(.medium)
            }

            HStack {
                Text("Bed Type:")
                Spacer()
                Text(bed.type.rawValue.capitalized)
                    .fontWeight(.medium)
            }

            Divider()

            HStack {
                Text("Total Amount:")
                Spacer()
                Text("₹\(bed.price)") // Fetch price from Bed
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    // MARK: - Payment Methods Section
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Payment Method")
                .font(.headline)
                .foregroundColor(.mint)

            VStack {
                ForEach(paymentMethods, id: \.type) { method in
                    HStack {
                        Image(systemName: method.icon)
                            .foregroundColor(.mint)
                        Text(method.name)
                        Spacer()
                        if selectedPaymentMethod == method.type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .onTapGesture {
                        selectedPaymentMethod = method.type
                    }
                }
            }
        }
    }

    // MARK: - Payment Fields Section
    private var paymentFieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter Payment Details")
                .font(.headline)
                .foregroundColor(.mint)

            if selectedPaymentMethod == .card {
                VStack(spacing: 12) {
                    TextField("Card Number", text: $cardNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Expiry Date (MM/YY)", text: $expiryDate)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    SecureField("CVV", text: $cvv)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } else if selectedPaymentMethod == .upi {
                TextField("UPI ID", text: $upiId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    // MARK: - Pay Button
    private var payButton: some View {
        Button(action: {
            showingConfirmation = true
        }) {
            HStack {
                Image(systemName: "lock.fill")
                Text("Pay ₹\(bed.price)")
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.mint)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .padding(.top)
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
            isAvailbale: true
        )

        NavigationView {
            BedPaymentView(
                bedBooking: sampleBedBooking,
                bed: sampleBed,  // Passing Bed separately
                hospital: sampleHospital
            )
        }
    }
}
