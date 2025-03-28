import SwiftUI

struct EmergencyBookingConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    let appointment: Appointment
    let hospital: Hospital
    let invoice: Invoice
    let patient: Patient

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // ✅ Success Icon
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.mint)
                        .padding(.top)

                    // ✅ Success Message
                    Text("Emergency Booking Confirmed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)

                    Text("Your emergency request has been successfully submitted to the hospital.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // ✅ Emergency & Payment Details
                    emergencyDetailsSection
                    invoiceDetailsSection

                    // ✅ Invoice Button
                    Button(action: viewInvoice) {
                        Text("View Invoice")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }

            // ✅ Fixed Done & View Voice Buttons
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

    // MARK: - Emergency Details Section
    private var emergencyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Details")
                .font(.headline)
                .foregroundColor(.mint)

            detailRow(label: "Patient Name", value: patient.fullname)
            detailRow(label: "Emergency Type", value: appointment.type.rawValue.capitalized)
            detailRow(label: "Hospital", value: hospital.name)
            detailRow(label: "Date & Time", value: formattedDateTime)

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

            detailRow(label: "Emergency ID", value: String(appointment.id.uuidString.prefix(8)))
            detailRow(label: "Payment Method", value: formattedPaymentMethod)
            detailRow(label: "Amount Paid", value: "₹\(invoice.amount)")
            detailRow(label: "Payment Status", value: invoice.status.rawValue.capitalized)

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
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy • h:mm a"
        return formatter.string(from: appointment.date)
    }

    // MARK: - View Invoice Action
    private func viewInvoice() {
        // Implement invoice viewing logic
        print("Invoice viewed")
    }
    
    // MARK: - View Voice Action
    private func viewVoice() {
        // Implement voice feedback logic
        print("Voice viewed")
    }
}

// MARK: - Preview
struct EmergencyBookingConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleHospital = Hospital(
            id: UUID(),
            name: "AIIMS Hospital",
            address: "456, Emergency Road",
            city: "Mumbai",
            state: "Maharashtra",
            pincode: "400001",
            mobile_number: "9876543210",
            email: "contact@aiims.com",
            license_number: "HOSP67890",
            is_active: true
        )

        let samplePatient = Patient(
            id: UUID(),
            fullName: "Rajesh Gupta",
            gender: "Male",
            dateOfBirth: Date(),
            contactNo: "9876543210",
            email: "rajesh@example.com"
        )

        let sampleAppointment = Appointment(
            id: UUID(),
            patientId: samplePatient.id,
            doctorId: UUID(),
            date: Date(),
            status: .scheduled,
            createdAt: Date(),
            type: .Emergency
        )

        let sampleInvoice = Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: samplePatient.id,
            amount: 5000,
            paymentType: .appointment,
            status: .paid,
            hospitalId: UUID()
        )

        NavigationView {
            EmergencyBookingConfirmationView(
                appointment: sampleAppointment,
                hospital: sampleHospital,
                invoice: sampleInvoice,
                patient: samplePatient
            )
        }
    }
}
