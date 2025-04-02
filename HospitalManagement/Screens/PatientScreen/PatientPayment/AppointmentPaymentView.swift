import SwiftUI

struct PaymentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    let appointment: Appointment
    let doctor: Doctor
    let department: Department
    let hospital: Hospital
    @State private var selectedPaymentMethod: PaymentOption = .applePay
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var upiId = ""
    @State private var showPaymentConfirmation = false
    @State private var invoice: Invoice?
    @StateObject private var coordinator = NavigationCoordinator.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        Text("Make Payment")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                            .padding(.top)

                        // Booking Details Section
                        bookingDetailsSection

                        // Payment Methods
                        paymentMethodsSection

                        // Payment Input Fields
                        if selectedPaymentMethod != .applePay {
                            paymentFieldsSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                // Fixed Pay Button
                VStack {
                    Divider()
                    Button(action: {
                        processPayment()
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Pay ₹\(department.fees)")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    .padding()
                }
                .background(Color.white)
                .shadow(radius: 3)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showPaymentConfirmation, onDismiss: {
            if coordinator.isNavigatingBack {
                dismiss()
            }
        }) {
            if let generatedInvoice = invoice {
                NavigationView {
                    AppointmentPaymentConfirmationView(
                        appointment: appointment,
                        doctor: doctor,
                        department: department,
                        hospital: hospital,
                        invoice: generatedInvoice
                    )
                }
            }
        }
        .onChange(of: coordinator.isNavigatingBack) { oldValue, isNavigating in
            if isNavigating {
                showPaymentConfirmation = false
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    private func processPayment() {
        // Create a paid invoice
        let paidInvoice = Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: appointment.patientId,
            amount: Int(department.fees),
            paymentType: .appointment,
            status: .paid,
            hospitalId: hospital.id
        )
        
        // Store the invoice and show confirmation
        invoice = paidInvoice
        showPaymentConfirmation = true
    }

    // MARK: - Booking Details Section
    private var bookingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Details")
                .font(.headline)
                .foregroundColor(.mint)

            detailRow(label: "Doctor", value: doctor.full_name)
            detailRow(label: "Specialization", value: department.name)
            detailRow(label: "Hospital", value: hospital.name)
            detailRow(label: "Date & Time", value: formattedDateTime)
            detailRow(label: "Appointment Type", value: appointment.type.rawValue.capitalized)

            Divider()

            HStack {
                Text("Total Amount:")
                Spacer()
                Text("₹\(department.fees)")
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

    // MARK: - Date Formatter
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy • h:mm a"
        return formatter.string(from: appointment.date)
    }
}


// MARK: - Preview
struct PaymentView_Previews: PreviewProvider {
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
            type: .Consultation,
            prescriptionId: UUID()
        )

        NavigationView {
            PaymentView(
                appointment: sampleAppointment,
                doctor: sampleDoctor,
                department: sampleDepartment,
                hospital: sampleHospital
            )
        }
    }
}
