import SwiftUI

struct AppointmentPaymentConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showInvoice = false
    @StateObject private var coordinator = NavigationCoordinator.shared
    @Environment(\.presentationMode) var presentationMode
    
    let appointment: Appointment
    let doctor: Doctor
    let department: Department
    let hospital: Hospital
    let invoice: Invoice
    
    init(appointment: Appointment, doctor: Doctor, department: Department, hospital: Hospital, invoice: Invoice) {
        self.appointment = appointment
        self.doctor = doctor
        self.department = department
        self.hospital = hospital
        self.invoice = invoice
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // ✅ Success Icon
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppConfig.buttonColor)
                        .padding(.top)

                    // ✅ Success Message
                    Text("Payment Successful")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.buttonColor)

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
                    Button(action: {
                        print("👆 PaymentConfirmationView: Done button tapped")
                        
                        // First dismiss this sheet
                        dismiss()
                        
                        // Handle navigation and update appointments
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Switch to appointments tab
                            coordinator.activeTab = 1
                            
                            // Reset navigation state
                            coordinator.resetNavigation()
                            coordinator.isNavigatingBack = true
                            
                            // Create appointment dictionary
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            
                            // Create time formatter for time slot
                            let timeFormatter = DateFormatter()
                            timeFormatter.dateFormat = "hh:mm a"
                            
                            let appointmentDict: [String: Any] = [
                                "id": appointment.id.uuidString,
                                "patientId": appointment.patientId.uuidString,
                                "doctorId": appointment.doctorId.uuidString,
                                "date": dateFormatter.string(from: appointment.date),
                                "timeSlot": timeFormatter.string(from: appointment.date),
                                "type": appointment.type.rawValue,
                                "status": appointment.status.rawValue,
                                "createdAt": dateFormatter.string(from: appointment.createdAt),
                                "doctorName": doctor.full_name,
                                "departmentName": department.name,
                                "hospitalName": hospital.name,
                                "amount": invoice.amount
                            ]
                            
                            // Post notification to update appointments tab
                            NotificationCenter.default.post(
                                name: NSNotification.Name("AppointmentBooked"),
                                object: nil,
                                userInfo: ["appointment": appointmentDict]
                            )
                            
                            // Post notification for navigation
                            NotificationCenter.default.post(
                                name: NSNotification.Name("NavigateToSelectDoctor"),
                                object: nil
                            )
                        }
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(AppConfig.backgroundColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppConfig.buttonColor)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .background(AppConfig.cardColor)
            .shadow(radius: 3)
        }
        .background(AppConfig.backgroundColor)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showInvoice) {
            InvoiceView(invoice: invoice)
        }
        .onAppear {
            print("👀 PaymentConfirmationView: View appeared")
        }
        .onDisappear {
            print("👋 PaymentConfirmationView: View disappeared")
        }
    }

    // MARK: - Appointment Details Section
    private var appointmentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appointment Details")
                .font(.headline)
                .foregroundColor(AppConfig.buttonColor)

            detailRow(label: "Doctor", value: doctor.full_name)
            detailRow(label: "Specialization", value: department.name)
            detailRow(label: "Hospital", value: hospital.name)
            detailRow(label: "Date & Time", value: formattedDateTime)
            detailRow(label: "Appointment Type", value: appointment.type.rawValue.capitalized)

            Divider()
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color:AppConfig.shadowColor,radius: 3)
    }

    // MARK: - Invoice Details Section
    private var invoiceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Details")
                .font(.headline)
                .foregroundColor(AppConfig.buttonColor)

            detailRow(label: "Appointment ID", value: appointment.id.uuidString)
            detailRow(label: "Payment Method", value: formattedPaymentMethod)
            detailRow(label: "Amount Paid", value: "₹\(invoice.amount)")

            Divider()
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color:AppConfig.shadowColor,radius: 3)
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
            is_first_login: true,
            initial_password: "password123",
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
            is_active: true,
            assigned_admin_id: nil
        )

        let sampleAppointment = Appointment(
            id: UUID(),
            patientId: UUID(),
            doctorId: UUID(),
            date: Date(),
            status: AppointmentStatus.scheduled,
            createdAt: Date(),
            type: AppointmentType.Consultation,
            prescriptionId: UUID()
        )

        let sampleInvoice = Invoice(
            id: UUID(),
            createdAt: Date(),
            patientid: UUID(),
            amount: 2000,
            paymentType: .appointment,
            status: .paid,
            hospitalId: UUID()
        )

        NavigationView {
            AppointmentPaymentConfirmationView(
                appointment: sampleAppointment,
                doctor: sampleDoctor,
                department: sampleDepartment,
                hospital: sampleHospital,
                invoice: sampleInvoice
            )
        }
    }
}

// Replace the RootPresentationModeKey implementation at the bottom with:

private struct RootPresentationModeKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var rootPresentationMode: Binding<Bool> {
        get { self[RootPresentationModeKey.self] }
        set { self[RootPresentationModeKey.self] = newValue }
    }
}

extension View {
    func rootPresentationMode(_ mode: Binding<Bool>) -> some View {
        environment(\.rootPresentationMode, mode)
    }
}
