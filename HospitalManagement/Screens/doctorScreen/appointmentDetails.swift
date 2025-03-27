import SwiftUI
import PhotosUI
import PDFKit

// Add this PDFGenerator class before the AppointmentDetailView struct
class PDFGenerator {
    static func generatePrescriptionPDF(data: PrescriptionData) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Hospital Management System",
            kCGPDFContextAuthor: "Doctor"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Draw content
            let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
            let regularFont = UIFont.systemFont(ofSize: 12)
            
            // Header
            drawText("Hospital Management System", at: CGPoint(x: 40, y: 40), font: titleFont)
            
            // Patient Details
            drawText("Patient ID: \(data.patientId)", at: CGPoint(x: 40, y: 80), font: regularFont)
            
            // Diagnosis
            var yPos = 120.0
            drawText("Diagnosis:", at: CGPoint(x: 40, y: yPos), font: regularFont)
            drawText(data.diagnosis, at: CGPoint(x: 60, y: yPos + 20), font: regularFont)
            
            // Lab Tests
            yPos += 60
            drawText("Lab Tests:", at: CGPoint(x: 40, y: yPos), font: regularFont)
            if let tests = data.labTests {
                for (index, test) in tests.enumerated() {
                    yPos += 20
                    drawText("• \(test)", at: CGPoint(x: 60, y: yPos), font: regularFont)
                }
            }
            
            // Medicine
            yPos += 40
            drawText("Medicine:", at: CGPoint(x: 40, y: yPos), font: regularFont)
            if let medicine = data.medicineName {
                yPos += 20
                drawText("• \(medicine)", at: CGPoint(x: 60, y: yPos), font: regularFont)
                if let dosage = data.medicineDosage, let duration = data.medicineDuration {
                    yPos += 15
                    drawText("  \(dosage.rawValue) - \(duration.rawValue)", at: CGPoint(x: 60, y: yPos), font: regularFont)
                }
            }
            
            // Additional Notes
            yPos += 40
            drawText("Additional Notes:", at: CGPoint(x: 40, y: yPos), font: regularFont)
            if let notes = data.additionalNotes {
                drawText(notes, at: CGPoint(x: 60, y: yPos + 20), font: regularFont)
            }
        }
        
        return data
    }
    
    private static func drawText(_ text: String, at point: CGPoint, font: UIFont) {
        let attributes = [
            NSAttributedString.Key.font: font
        ]
        (text as NSString).draw(at: point, withAttributes: attributes)
    }
}

// First, add this class at the top level of your file
class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
}

struct AppointmentDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var supabase = SupabaseController()
    
    let appointment: Appointment
    
    @State private var selectedImage: UIImage?
    @State private var diagnosticTests: String = ""
    @State private var existingPrescription: PrescriptionData?
    @State private var isLoadingPrescription = true
    @State private var prescriptionError: Error?
    
    // Add new state variables for prescription
    @State private var diagnosis: String = ""
    @State private var selectedLabTests: Set<String> = []
    @State private var customLabTest: String = ""
    @State private var additionalNotes: String = ""
    
    @State private var showingLabTestPicker = false
    @State private var prescriptionPDF: Data?
    @State private var showingShareSheet = false
    @State private var showingPrescriptionPreview = false
    
    // Medicine-related state
    @State private var medicineName: String = ""
    @State private var selectedDosage: DosageOption = .oneDaily
    @State private var selectedDuration: DurationOption = .sevenDays
    
    // Predefined lab tests
    let availableLabTests = [
        "Complete Blood Count",
        "Blood Sugar Test",
        "Lipid Profile",
        "Thyroid Function Test",
        "Liver Function Test",
        "Kidney Function Test",
        "X-Ray",
        "ECG"
    ]
    
    @State private var showingMedicineSelection = false
    @State private var prescribedMedicines: [PrescribedMedicine] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoadingPrescription {
                    ProgressView("Loading prescription...")
                } else {
                    List {
                        // Appointment Details Section
                        Section(header: Text("Appointment Details").font(.headline)) {
                            InfoRowAppointment(label: "Appointment Type", value: appointment.type.rawValue)
                            InfoRowAppointment(label: "Date & Time", value: formatDate(appointment.date))
                            InfoRowAppointment(label: "Status", value: appointment.status.rawValue)
                        }
                        
                        // Prescription Section
                        Section(header: Text("Prescription").font(.headline)) {
                            if let prescription = existingPrescription {
                                // Show existing prescription data
                                Text("Diagnosis: \(prescription.diagnosis)")
                                if let tests = prescription.labTests {
                                    Text("Lab Tests:")
                                    ForEach(tests, id: \.self) { test in
                                        Text("• \(test)")
                                    }
                                }
                                
                                // Medicine Section
                                if let medicineName = prescription.medicineName,
                                   let dosage = prescription.medicineDosage,
                                   let duration = prescription.medicineDuration {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Medicine: \(medicineName)")
                                            .font(.headline)
                                        Text("\(dosage.rawValue) - \(duration.rawValue)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                                
                                if let notes = prescription.additionalNotes {
                                    Text("Additional Notes: \(notes)")
                                }
                            } else {
                                // Show prescription input fields
                                DiagnosisSection(diagnosis: $diagnosis)
                                LabTestsSection(selectedLabTests: $selectedLabTests, showingLabTestPicker: $showingLabTestPicker)
                                
                                NotesSection(notes: $additionalNotes)
                            }
                        }
                        
                        // Medicine Section
                        Section(header: Text("MEDICINES").font(.headline)) {
                            HStack {
                                Text("Selected Medicines")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Button(action: {
                                    showingMedicineSelection = true
                                }) {
                                    Label("Add Medicine", systemImage: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if prescribedMedicines.isEmpty {
                                Text("No medicines selected")
                                    .foregroundColor(.gray)
                                    .italic()
                            } else {
                                ForEach(prescribedMedicines) { medicine in
                                    VStack(alignment: .leading) {
                                        Text(medicine.medicine.name)
                                            .font(.headline)
                                        Text("\(medicine.dosage) for \(medicine.duration)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    
                    // View Prescription Button
                    Button(action: {
                        generateAndShowPrescription()
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("View Prescription")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Appointment Details")
            .navigationBarItems(trailing: Button("Save") {
                savePrescription()
                presentationMode.wrappedValue.dismiss()
            })
            .task {
                await loadPrescription()
            }
            .sheet(isPresented: $showingLabTestPicker) {
                LabTestPickerView(selectedTests: $selectedLabTests, availableTests: availableLabTests)
            }
            .sheet(isPresented: $showingPrescriptionPreview) {
                if let pdfData = prescriptionPDF {
                    PDFPreviewView(pdfData: pdfData)
                }
            }
            .sheet(isPresented: $showingMedicineSelection) {
                MedicineSelectionView(prescribedMedicines: $prescribedMedicines)
            }
        }
    }
    
    private func loadPrescription() async {
        isLoadingPrescription = true
        do {
            print("Loading prescription for ID:", appointment.prescriptionId.uuidString)
            let prescriptions: [PrescriptionData] = try await supabase.client
                .from("PrescriptionData") // Changed from "prescriptions" to "PrescriptionData"
                .select()
                .eq("id", value: appointment.prescriptionId.uuidString)
                .execute()
                .value
            
            if let prescription = prescriptions.first {
                existingPrescription = prescription
                diagnosis = prescription.diagnosis
                if let tests = prescription.labTests {
                    selectedLabTests = Set(tests)
                }
                additionalNotes = prescription.additionalNotes ?? ""
            }
        } catch {
            print("Error loading prescription:", error)
        }
        isLoadingPrescription = false
    }
    
    func savePrescription() {
        let prescriptionData = PrescriptionData(
            id: UUID(),
            patientId: appointment.patientId,
            doctorId: appointment.doctorId,
            diagnosis: diagnosis,
            labTests: Array(selectedLabTests),
            additionalNotes: additionalNotes,
            medicineName: medicineName,
            medicineDosage: selectedDosage,
            medicineDuration: selectedDuration
        )
        
        if let pdfData = PDFGenerator.generatePrescriptionPDF(data: prescriptionData) {
            self.prescriptionPDF = pdfData
            showingPrescriptionPreview = true
        }
    }
    
    private func generateAndShowPrescription() {
        let prescriptionData = existingPrescription ?? PrescriptionData(
            id: UUID(),
            patientId: appointment.patientId,
            doctorId: appointment.doctorId,
            diagnosis: diagnosis,
            labTests: Array(selectedLabTests),
            additionalNotes: additionalNotes,
            medicineName: medicineName,
            medicineDosage: selectedDosage,
            medicineDuration: selectedDuration
        )
        
        if let pdfData = PDFGenerator.generatePrescriptionPDF(data: prescriptionData) {
            self.prescriptionPDF = pdfData
            self.showingPrescriptionPreview = true
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy - h:mm a"
        return formatter.string(from: date)
    }
    
    // Helper Views
    struct InfoRowAppointment: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(value)
                    .font(.body)
            }
        }
    }
    
    struct LabTestPickerView: View {
        @Environment(\.presentationMode) var presentationMode
        @Binding var selectedTests: Set<String>
        let availableTests: [String]
        
        var body: some View {
            NavigationView {
                List {
                    ForEach(availableTests, id: \.self) { test in
                        HStack {
                            Text(test)
                            Spacer()
                            if selectedTests.contains(test) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTests.contains(test) {
                                selectedTests.remove(test)
                            } else {
                                selectedTests.insert(test)
                            }
                        }
                    }
                }
                .navigationTitle("Select Lab Tests")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    struct DiagnosisSection: View {
        @Binding var diagnosis: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Diagnosis")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                TextEditor(text: $diagnosis)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.vertical, 8)
        }
    }
    
    struct LabTestsSection: View {
        @Binding var selectedLabTests: Set<String>
        @Binding var showingLabTestPicker: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Lab Tests")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Button(action: {
                        showingLabTestPicker = true
                    }) {
                        Label("Add Tests", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                if selectedLabTests.isEmpty {
                    Text("No lab tests selected")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(Array(selectedLabTests), id: \.self) { test in
                        LabTestRow(test: test) {
                            selectedLabTests.remove(test)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    struct LabTestRow: View {
        let test: String
        let onDelete: () -> Void
        
        var body: some View {
            HStack {
                Text("• \(test)")
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    struct NotesSection: View {
        @Binding var notes: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Notes")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.vertical, 8)
        }
    }
    
    struct PDFPreviewView: View {
        @Environment(\.presentationMode) var presentationMode
        let pdfData: Data
        
        var body: some View {
            NavigationView {
                PDFKitView(data: pdfData)
                    .navigationTitle("Prescription")
                    .navigationBarItems(
                        leading: Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        },
                        trailing: ShareLink(
                            item: pdfData,
                            preview: SharePreview(
                                "Prescription",
                                image: Image(systemName: "doc.text.fill")
                            )
                        )
                    )
            }
        }
    }
    
    struct PDFKitView: UIViewRepresentable {
        let data: Data
        
        func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = PDFDocument(data: data)
            pdfView.autoScales = true
            return pdfView
        }
        
        func updateUIView(_ uiView: PDFView, context: Context) {
            uiView.document = PDFDocument(data: data)
        }
    }
    
    // Update the MedicineSelectionView
    struct MedicineSelectionView: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var prescribedMedicines: [PrescribedMedicine]
        
        @State private var searchText = ""
        @State private var searchResults: [MedicineResponse] = []
        @State private var isSearching = false
        @State private var selectedMedicine: MedicineResponse?
        @State private var showingDosageSheet = false
        
        // Add debouncer
        private let searchDebouncer = Debouncer(delay: 0.4) // 400ms delay
        
        var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Search Bar - Fixed at top
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search medicines...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onChange(of: searchText) { newValue in
                                    if !newValue.isEmpty && newValue.count >= 2 {
                                        // Use debouncer for search
                                        isSearching = true // Show loading immediately
                                        searchDebouncer.debounce {
                                            searchMedicines(query: newValue)
                                        }
                                    } else {
                                        searchResults = []
                                        isSearching = false
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: { 
                                    withAnimation {
                                        searchText = ""
                                        searchResults = []
                                        isSearching = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(4)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Content Area
                    if isSearching {
                        Spacer()
                        ProgressView("Searching...")
                        Spacer()
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        Spacer()
                        NoResultsView()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { medicine in
                                    MedicineCard(medicine: medicine) {
                                        selectedMedicine = medicine
                                        showingDosageSheet = true
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .navigationTitle("Select Medicine")
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() }
                )
                .sheet(isPresented: $showingDosageSheet) {
                    if let medicine = selectedMedicine {
                        DosageSelectionView(medicine: medicine) { dosage, duration in
                            addMedicine(medicine, dosage: dosage, duration: duration)
                            dismiss()
                        }
                    }
                }
            }
        }
        
        private func searchMedicines(query: String) {
            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                isSearching = false
                return
            }
            
            let urlString = "https://hms-server-4kjy.onrender.com/search?name=\(encodedQuery)"
            guard let url = URL(string: urlString) else {
                isSearching = false
                return
            }
            
            print("Searching for: \(query)")
            print("URL: \(urlString)")
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    isSearching = false
                    
                    if let error = error {
                        print("Network error:", error.localizedDescription)
                        return
                    }
                    
                    guard let data = data else {
                        print("No data received")
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let results = try decoder.decode([MedicineResponse].self, from: data)
                        print("Decoded \(results.count) medicines")
                        searchResults = results
                    } catch {
                        print("Decoding error:", error)
                        print("Response data:", String(data: data, encoding: .utf8) ?? "Unable to convert data to string")
                        searchResults = []
                    }
                }
            }.resume()
        }
        
        private func addMedicine(_ medicine: MedicineResponse, dosage: String, duration: String) {
            let prescribed = PrescribedMedicine(
                medicine: medicine,
                dosage: dosage,
                duration: duration,
                timing: ""
            )
            prescribedMedicines.append(prescribed)
        }
    }
    
    // Add these new view components
    struct NoResultsView: View {
        var body: some View {
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
                
                Text("No medicines found")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Try searching with a different name")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .frame(maxWidth: .infinity)
        }
    }
    
    struct MedicineCard: View {
        let medicine: MedicineResponse
        let onSelect: () -> Void
        
        var body: some View {
            Button(action: onSelect) {
                HStack(spacing: 16) {
                    // Medicine Icon/Image
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "pills.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        )
                    
                    // Medicine Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicine.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Tap to select")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.systemGray4))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
    
    // Add this new view for dosage selection
    struct DosageSelectionView: View {
        let medicine: MedicineResponse
        let onComplete: (String, String) -> Void
        @Environment(\.dismiss) private var dismiss
        
        @State private var selectedDosage = "Once Daily"
        @State private var selectedDuration = "7 Days"
        
        let dosageOptions = ["Once Daily", "Twice Daily", "Thrice Daily", "Four times a day"]
        let durationOptions = ["3 Days", "5 Days", "7 Days", "10 Days", "15 Days", "30 Days"]
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Medicine")) {
                        Text(medicine.name)
                            .font(.headline)
                    }
                    
                    Section(header: Text("Dosage")) {
                        Picker("Dosage", selection: $selectedDosage) {
                            ForEach(dosageOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    }
                    
                    Section(header: Text("Duration")) {
                        Picker("Duration", selection: $selectedDuration) {
                            ForEach(durationOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    }
                }
                .navigationTitle("Prescription Details")
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() },
                    trailing: Button("Done") {
                        onComplete(selectedDosage, selectedDuration)
                        dismiss()
                    }
                )
            }
        }
    }
}
