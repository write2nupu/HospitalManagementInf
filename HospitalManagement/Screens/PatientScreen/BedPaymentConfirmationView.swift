import SwiftUI

struct BedPaymentConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    let bedBooking: BedBooking
    let hospital: Hospital
    let invoice: Invoice

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.mint)
                        .padding(.top)

                    // Success Message
                    Text("Payment Successful")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)

                    Text("Your bed booking has been confirmed.")
                        .font(.body)
                        .foregroundColor(.gray)

                    // Bed Booking & Payment Details
                    bedDetailsSection
                    invoiceDetailsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }

            // Fixed Buttons
            VStack {
                Divider()
                
                HStack {
                    // View Invoice Button
                    Button(action: { viewInvoice() }) {
                        Text("View Invoice")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    
                    // Done Button
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mint)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .background(Color.white)
            .shadow(radius: 3)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Bed Booking Details Section
    private var bedDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bed Booking Details")
                .font(.headline)
                .foregroundColor(.mint)

            detailRow(label: "Bed Type", value: bedBooking.type.rawValue)
            detailRow(label: "Hospital", value: hospital.name)
            detailRow(label: "Booking Date", value: formattedBookingDate)
            detailRow(label: "Total Price", value: "₹\(bedBooking.price)")

            Divider()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    // MARK: - Invoice Details Section
    private var invoiceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Details")
                .font(.headline)
                .foregroundColor(.mint)

            detailRow(label: "Booking ID", value: bedBooking.id.uuidString)
            detailRow(label: "Payment Method", value: formattedPaymentMethod)
            detailRow(label: "Amount Paid", value: "₹\(invoice.amount)")

            Divider()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    // MARK: - Detail Row Helper Function
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .fontWeight(.regular)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Format Payment Method
    private var formattedPaymentMethod: String {
        switch invoice.paymentType {
        case .appointment:
            return "Apple Pay"
        case .labTest:
            return "Credit/Debit Card"
        case .bed:
            return "UPI"
        }
    }

    // MARK: - Date Formatter
    private var formattedBookingDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: bedBooking.bookingDate)
    }

    // MARK: - View Invoice Function
    private func viewInvoice() {
        // Navigate to Invoice View (To be implemented)
        print("Viewing Invoice for Booking ID: \(bedBooking.id)")
    }
}

// MARK: - Preview
struct BedPaymentConfirmationView_Previews: PreviewProvider {
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
            is_active: true
        )

        let sampleBedBooking = BedBooking(
            id: UUID(),
            patientId: UUID(),
            hospitalId: UUID(),
            type: .ICU,
            price: 5000,
            bookingDate: Date()
        )

        let sampleInvoice = Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: UUID(),
            amount: 5000,
            paymentType: .bed,
            status: .paid
        )

        NavigationView {
            BedPaymentConfirmationView(
                bedBooking: sampleBedBooking,
                hospital: sampleHospital,
                invoice: sampleInvoice
            )
        }
    }
}
