import SwiftUI

struct BedBookingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabaseController = SupabaseController()
    @State private var selectedBedType: BedType = .General
    @State private var availableBeds: [BedType: (total: Int, available: Int)] = [:]
    @State private var fromDate = Date()
    @State private var toDate = Date()
    @State private var navigateToPayment = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedBed: Bed?
    @State private var patient: Patient?
    @AppStorage("currentUserId") private var currentUserId: String = ""
    
    let hospital: Hospital
    
    var body: some View {
        ScrollView {
            VStack {
                if isLoading {
                    ProgressView("Loading bed availability...")
                } else {
                    if patient != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Bed Type")
                                .font(.headline)
                                .foregroundColor(AppConfig.buttonColor)
                            Picker("Bed Type", selection: $selectedBedType) {
                                Text("General").tag(BedType.General)
                                Text("ICU").tag(BedType.ICU)
                                Text("Personal").tag(BedType.Personal)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedBedType) { oldValue, newValue in
                                Task {
                                    await fetchAvailableBeds(type: newValue)
                                }
                            }
                            
                            Text("Price")
                                .font(.headline)
                                .foregroundColor(AppConfig.buttonColor)
                            Text("₹\(calculateTotalPrice())")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppConfig.buttonColor.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Available Beds")
                                .font(.headline)
                                .foregroundColor(AppConfig.buttonColor)
                            Text("\(availableBeds[selectedBedType]?.available ?? 0) beds available")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppConfig.buttonColor.opacity(0.1))
                                .cornerRadius(8)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("From Date")
                                        .font(.body)
                                    Spacer()
                                    DatePicker("", selection: $fromDate, in: Date()..., displayedComponents: .date)
                                        .labelsHidden()
                                        .accentColor(.mint)
                                        .onChange(of: fromDate) { oldValue, _ in
                                            if toDate < fromDate {
                                                toDate = Calendar.current.date(byAdding: .day, value: 1, to: fromDate) ?? fromDate
                                            }
                                        }
                                }
                                .padding()
                                .background(AppConfig.buttonColor.opacity(0.1))
                                .cornerRadius(8)
                                
                                HStack {
                                    Text("To Date")
                                        .font(.body)
                                    Spacer()
                                    DatePicker("", selection: $toDate, in: fromDate..., displayedComponents: .date)
                                        .labelsHidden()
                                        .accentColor(AppConfig.buttonColor)
                                }
                                .padding()
                                .background(AppConfig.buttonColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .rigid)
                            generator.impactOccurred()
                            proceedToPayment()
                        }) {
                            Text("Proceed to Payment")
                                .fontWeight(.semibold)
                                .foregroundColor(AppConfig.backgroundColor)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedBed != nil ? AppConfig.buttonColor : Color.gray)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                        }
                        .disabled(selectedBed == nil)
                        .padding()
                    } else {
                        Text("Please log in as a patient to book a bed")
                            .foregroundColor(AppConfig.redColor)
                            .padding()
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(AppConfig.redColor)
                        .padding()
                }
            }
        }
        .navigationTitle("Book Bed")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $navigateToPayment) {
            if let bedBooking = createBedBooking(), let bed = selectedBed, let currentPatient = patient {
                NavigationStack {
                    BedPaymentView(
                        bedBooking: bedBooking,
                        bed: Bed(
                            id: bed.id,
                            hospitalId: bed.hospitalId,
                            price: calculateTotalPrice(),
                            type: bed.type,
                            isAvailable: bed.isAvailable
                        ),
                        hospital: hospital,
                        onPaymentSuccess: { invoice in
                            Task {
                                do {
                                    try await supabaseController.createBedBooking(
                                        patientId: currentPatient.id,
                                        bedId: bed.id,
                                        hospitalId: hospital.id,
                                        startDate: fromDate,
                                        endDate: toDate
                                    )
                                    print("Bed booking created successfully")

                                    try await supabaseController.updateBedAvailability(
                                        bedId: bed.id,
                                        isAvailable: false
                                    )
                                    print("Bed availability updated successfully")

                                    let updatedInvoice = Invoice(
                                        id: UUID(),
                                        createdAt: Date(),
                                        patientid: currentPatient.id,
                                        amount: bed.price,
                                        paymentType: .bed,
                                        status: .paid,
                                        hospitalId: hospital.id
                                    )
                                    try await supabaseController.createInvoice(invoice: updatedInvoice)
                                    print("Invoice created successfully")

                                    DispatchQueue.main.async {
                                        dismiss()
                                    }
                                } catch {
                                    print("Error in booking process: \(error.localizedDescription)")
                                    errorMessage = "Failed to complete booking: \(error.localizedDescription)"
                                }
                            }
                        }
                    )
                }
            }
        }
        .task {
            await loadInitialData()
        }
    }
    
    private func loadInitialData() async {
        isLoading = true
        do {
            // First load the patient details using the stored patient ID
            if let patientId = UserDefaults.standard.string(forKey: "currentPatientId"),
               let patientUUID = UUID(uuidString: patientId) {
                if let patientDetails = try await supabaseController.fetchPatientDetails(patientId: patientUUID) {
                    self.patient = patientDetails
                } else {
                    errorMessage = "No patient record found. Please ensure you are logged in as a patient."
                }
            } else {
                errorMessage = "Please log in to book a bed."
            }
            
            // Then load bed statistics
            let stats = try await supabaseController.getBedStatistics(hospitalId: hospital.id)
            availableBeds = stats.byType
            await fetchAvailableBeds(type: selectedBedType)
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func fetchAvailableBeds(type: BedType) async {
        do {
            let beds = try await supabaseController.getAvailableBedsByType(type: type, hospitalId: hospital.id)
            // Only select the first available bed
            selectedBed = beds.first
        } catch {
            errorMessage = "Failed to fetch available beds: \(error.localizedDescription)"
        }
    }
    
    private func createBedBooking() -> BedBooking? {
        guard let selectedBed = selectedBed,
              let currentPatient = patient else { return nil }
        
        return BedBooking(
            id: UUID(),
            patientId: currentPatient.id,
            hospitalId: hospital.id,
            bedId: selectedBed.id,
            startDate: fromDate,
            endDate: toDate,
            isAvailable: true
        )
    }
    
    private func proceedToPayment() {
        if selectedBed != nil {
            navigateToPayment = true
        }
    }
    
    private func calculateTotalPrice() -> Int {
        guard let bed = selectedBed else { return 0 }
        
        let numberOfDays = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day ?? 0
        // Add 1 to include both start and end dates
        let totalDays = numberOfDays + 1
        return bed.price * totalDays
    }
}

// Preview provider
struct BedBookingView_Previews: PreviewProvider {
    static var previews: some View {
        BedBookingView(
            hospital: Hospital(
                id: UUID(),
                name: "Preview Hospital",
                address: "123 Test St",
                city: "Test City",
                state: "Test State",
                pincode: "12345",
                mobile_number: "1234567890",
                email: "test@test.com",
                license_number: "TEST123",
                is_active: true,
                assigned_admin_id: nil
            )
        )
    }
}
