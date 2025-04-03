import SwiftUI

struct BedPaymentConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    let bedBooking: BedBooking
    let hospital: Hospital
    let invoice: Invoice
    @State private var navigateToBookedBed = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Animation
                    LottieView(name: "payment-success")
                        .frame(width: 200, height: 200)
                    
                    // Success Message
                    VStack(spacing: 8) {
                        Text("Payment Successful!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.buttonColor)
                        
                        Text("Your bed has been booked successfully")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    // Booking Details Card
                    VStack(spacing: 20) {
                        // Hospital Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Hospital Details")
                                .font(.headline)
                                .foregroundColor(AppConfig.buttonColor)
                            
                            VStack(spacing: 8) {
                                detailRow(icon: "building.2", title: hospital.name)
                                detailRow(icon: "location", title: "\(hospital.address), \(hospital.city)")
                                detailRow(icon: "phone", title: hospital.mobile_number)
                            }
                        }
                        .padding()
                        .background(AppConfig.buttonColor.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Booking Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Booking Details")
                                .font(.headline)
                                .foregroundColor(AppConfig.buttonColor)
                            
                            VStack(spacing: 8) {
                                detailRow(icon: "calendar", title: "Check In: \(formatDate(bedBooking.startDate))")
                                detailRow(icon: "calendar", title: "Check Out: \(formatDate(bedBooking.endDate))")
                                detailRow(icon: "creditcard", title: "Payment ID: \(invoice.id.uuidString.prefix(8))")
                                detailRow(icon: "indianrupeesign", title: "Amount Paid: ₹\(invoice.amount)")
                            }
                        }
                        .padding()
                        .background(AppConfig.buttonColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            
            // Bottom Done Button
            Button(action: {
                // Dismiss both sheets
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: NSNotification.Name("DismissAllSheets"), object: nil)
                }
            }) {
                Text("Done")
                    .fontWeight(.semibold)
                    .foregroundColor(AppConfig.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConfig.buttonColor)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Booking Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func detailRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppConfig.buttonColor)
                .frame(width: 24)
            Text(title)
                .font(.body)
            Spacer()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct LottieView: View {
    let name: String
    
    var body: some View {
        Color.clear // Placeholder for Lottie animation
            .overlay(
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .foregroundColor(AppConfig.buttonColor)
                    .aspectRatio(contentMode: .fit)
                    .padding(40)
            )
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
            bedId: UUID(),
            startDate: Date(),
            endDate: Date(),
            isAvailable: true
        )

        let sampleInvoice = Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: UUID(),
            amount: 5000,
            paymentType: .bed,
            status: .paid,
            hospitalId: UUID()
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
