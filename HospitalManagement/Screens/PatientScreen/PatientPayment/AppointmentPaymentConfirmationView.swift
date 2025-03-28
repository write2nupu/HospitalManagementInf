import SwiftUI

struct PaymentConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showInvoice = false
    
    let appointment: Appointment
    let doctor: Doctor
    let department: Department
    let hospital: Hospital
    let invoice: Invoice

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
                    Text("Payment Successful")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)

                    Text("Your appointment has been confirmed.")
                        .font(.body)
                        .foregroundColor(.gray)

                    // ✅ Appointment & Payment Details
                    appointmentDetailsSection
                    invoiceDetailsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }

            // ✅ Fixed Buttons Section
            VStack {
                Divider()
                
                HStack(spacing: 12) {
                    Spacer()
                    
                    // ✅ View Invoice Button
                    Button(action: { showInvoice.toggle() }) {
                        Text("View Invoice")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    // ✅ Done Button
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
        .sheet(isPresented: $showInvoice) {
            InvoiceView(invoice: invoice)
        }
    }

    // MARK: - Appointment Details Section
    private var appointmentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appointment Details")
                .font(.headline)
                .foregroundColor(.mint)

            detailRow(label: "Doctor", value: doctor.full_name)
            detailRow(label: "Specialization", value: department.name)
            detailRow(label: "Hospital", value: hospital.name)
            detailRow(label: "Date & Time", value: formattedDateTime)
            detailRow(label: "Appointment Type", value: appointment.type.rawValue.capitalized)

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

            detailRow(label: "Appointment ID", value: appointment.id.uuidString)
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
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy • h:mm a"
        return formatter.string(from: appointment.date)
    }
}

// MARK: - Invoice View
struct InvoiceView: View {
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Invoice")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.mint)

            detailRow(label: "Invoice ID", value: invoice.id.uuidString)
            detailRow(label: "Date", value: formattedDate)
            detailRow(label: "Payment Method", value: formattedPaymentMethod)
            detailRow(label: "Amount Paid", value: "₹\(invoice.amount)")
            detailRow(label: "Status", value: invoice.status.rawValue.capitalized)

            Spacer()
        }
        .padding()
        .navigationTitle("Invoice Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

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
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: invoice.createdAt)
    }

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
}

// MARK: - Preview
struct PaymentConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleDoctor = Doctor(
            id: UUID(),
            full_name: "Dr. Ramesh Kumar",
            department_id: UUID(),
            hospital_id: UUID(),
            experience: 10,
            qualifications: "MBBS, MD",
            is_active: true,
            phone_num: "9876543210",
            email_address: "dr.ramesh@example.com",
            gender: "Male",
            license_num: "123456"
        )

        let sampleDepartment = Department(
            id: UUID(),
            name: "Cardiology",
            description: "Heart Specialist",
            hospital_id: UUID(),
            fees: 2000
        )

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

        let sampleAppointment = Appointment(
            id: UUID(),
            patientId: UUID(),
            doctorId: UUID(),
            date: Date(),
            status: .scheduled,
            createdAt: Date(),
            type: .Consultation
        )

        let sampleInvoice = Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: UUID(),
            amount: 2000,
            paymentType: .appointment,
            status: .paid
        )

        NavigationView {
            PaymentConfirmationView(
                appointment: sampleAppointment,
                doctor: sampleDoctor,
                department: sampleDepartment,
                hospital: sampleHospital,
                invoice: sampleInvoice
            )
        }
    }
}
