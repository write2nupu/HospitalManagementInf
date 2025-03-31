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
        NavigationStack {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Loading bed availability...")
                    } else {
                        if patient != nil {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Select Bed Type")
                                        .font(.headline)
                                        .foregroundColor(.mint)
                                    Picker("Bed Type", selection: $selectedBedType) {
                                        Text("General").tag(BedType.General)
                                        Text("ICU").tag(BedType.ICU)
                                        Text("Personal").tag(BedType.Personal)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .onChange(of: selectedBedType) { newValue in
                                        Task {
                                            await fetchAvailableBeds(type: newValue)
                                        }
                                    }
                                    
                                    Text("Price")
                                        .font(.headline)
                                        .foregroundColor(.mint)
                                    Text("₹\(selectedBed?.price ?? 0)")
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.mint.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Text("Available Beds")
                                        .font(.headline)
                                        .foregroundColor(.mint)
                                    Text("\(availableBeds[selectedBedType]?.available ?? 0) beds available")
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.mint.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    VStack(spacing: 16) {
                                        HStack {
                                            Text("From Date")
                                                .font(.body)
                                            Spacer()
                                            DatePicker("", selection: $fromDate, in: Date()..., displayedComponents: .date)
                                                .labelsHidden()
                                                .accentColor(.mint)
                                                .onChange(of: fromDate) { _ in
                                                    // Ensure toDate is always after fromDate
                                                    if toDate < fromDate {
                                                        toDate = Calendar.current.date(byAdding: .day, value: 1, to: fromDate) ?? fromDate
                                                    }
                                                }
                                        }
                                        .padding()
                                        .background(Color.mint.opacity(0.1))
                                        .cornerRadius(8)
                                        
                                        HStack {
                                            Text("To Date")
                                                .font(.body)
                                            Spacer()
                                            DatePicker("", selection: $toDate, in: fromDate..., displayedComponents: .date)
                                                .labelsHidden()
                                                .accentColor(.mint)
                                        }
                                        .padding()
                                        .background(Color.mint.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                            }
                            
                            Button(action: proceedToPayment) {
                                Text("Proceed to Payment")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedBed != nil ? Color.mint : Color.gray)
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                            }
                            .disabled(selectedBed == nil)
                            .padding()
                        } else {
                            Text("Please log in as a patient to book a bed")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Book Bed")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToPayment) {
                if let bedBooking = createBedBooking(), let bed = selectedBed, let currentPatient = patient {
                    BedPaymentView(
                        bedBooking: bedBooking,
                        bed: bed,
                        hospital: hospital,
                        onPaymentSuccess: { invoice in
                            Task {
                                do {
                                    // 1. Create the bed booking record in Supabase
                                    try await supabaseController.createBedBooking(
                                        patientId: currentPatient.id,
                                        bedId: bed.id,
                                        hospitalId: hospital.id,
                                        startDate: fromDate,
                                        endDate: toDate
                                    )
                                    print("Bed booking created successfully")

                                    // 2. Update bed availability status in Bed table
                                    try await supabaseController.updateBedAvailability(
                                        bedId: bed.id,
                                        isAvailable: false
                                    )
                                    print("Bed availability updated successfully")

                                    // 3. Create invoice record with all required fields
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

                                    // Dismiss this view after successful booking
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
            if let patientId = UUID(uuidString: currentUserId) {
                if let patientDetails = try await supabaseController.fetchPatientDetails(patientId: patientId) {
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
