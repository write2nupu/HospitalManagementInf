import SwiftUI

struct LabTestBookingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTests: [labTest.labTestName] = []
    @State private var preferredDate = Date()
    @State private var showTestSelection = false
    @State private var showPayment = false
    @State private var isLoading = false
    
    // Break down test prices into a function for better compiler performance
    private func getTestPrice(_ test: labTest.labTestName) -> Double {
        switch test {
        case .completeBloodCount: return 500
        case .bloodSugarTest: return 300
        case .lipidProfile: return 800
        case .thyroidFunctionTest: return 1200
        case .liverFunctionTest: return 1000
        case .kidneyFunctionTest: return 1000
        case .urineAnalysis: return 400
        case .vitaminDTest: return 900
        case .vitaminB12Test: return 800
        case .calciumTest: return 400
        case .cReactiveProtein: return 600
        case .erythrocyteSedimentationRate: return 400
        case .hba1c: return 700
        case .bloodCulture: return 1000
        case .urineCulture: return 800
        case .fastingBloodSugar: return 300
        case .postprandialBloodSugar: return 300
        }
    }
    
    private var totalAmount: Double {
        selectedTests.reduce(0) { $0 + getTestPrice($1) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                selectedTestsSection
                dateSelectionSection
                if !selectedTests.isEmpty {
                    totalAndPaymentSection
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Book Lab Test")
        .sheet(isPresented: $showTestSelection) {
            TestSelectionView(selectedTests: $selectedTests)
        }
        .sheet(isPresented: $showPayment) {
            labTestPaymentView(
                amount: totalAmount,
                selectedTests: selectedTests,
                preferredDate: preferredDate,
                onComplete: { success in
                    if success {
                        dismiss()
                    }
                }
            )
        }
    }
    
    // Break down the view into smaller components
    private var selectedTestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Selected Tests")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showTestSelection = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add Test")
                            .font(.body)
                    }
                    .foregroundColor(.mint)
                }
            }
            .padding(.horizontal)
            
            if selectedTests.isEmpty {
                Text("No tests selected")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(selectedTests, id: \.self) { test in
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(test.rawValue)
                                        .font(.system(size: 18))
                                        .foregroundColor(.primary)
                                    
                                    Text("₹\(Int(getTestPrice(test)))")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: { removeTest(test) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            
                            if test != selectedTests.last {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Date")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            DatePicker(
                "Preferred Date",
                selection: $preferredDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var totalAndPaymentSection: some View {
        Button(action: { showPayment = true }) {
            HStack {
                Text("Proceed to Payment")
                    .fontWeight(.semibold)
                Spacer()
                Text("₹\(Int(totalAmount))")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.mint)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private func removeTest(_ test: labTest.labTestName) {
        selectedTests.removeAll { $0 == test }
    }
}

struct TestSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTests: [labTest.labTestName]
    @State private var tempSelectedTests: [labTest.labTestName] = []
    
    var body: some View {
        NavigationView {
            List(labTest.labTestName.allCases, id: \.self) { test in
                HStack {
                    Text(test.rawValue)
                    Spacer()
                    if tempSelectedTests.contains(test) {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppConfig.buttonColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if tempSelectedTests.contains(test) {
                        tempSelectedTests.removeAll { $0 == test }
                    } else {
                        tempSelectedTests.append(test)
                    }
                }
            }
            .navigationTitle("Select Tests")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") {
                    selectedTests = tempSelectedTests
                    dismiss()
                }
            )
            .onAppear {
                tempSelectedTests = selectedTests
            }
        }
    }
}

struct labTestPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPaymentMethod: PaymentOption?
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    
    let amount: Double
    let selectedTests: [labTest.labTestName]
    let preferredDate: Date
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Make Payment")
                    .font(.title2)
                    .foregroundColor(.mint)
                    .padding(.vertical)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Booking Details Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Booking Details")
                                .font(.headline)
                                .foregroundColor(.mint)
                            
                            VStack(spacing: 16) {
                                detailRow(title: "Hospital:", value: "Apollo")
                                detailRow(title: "Date & Time:", value: "Thursday, Apr 3, 2025 • 11:00 AM")
                                detailRow(title: "Total Amount:", value: "₹\(String(format: "%.2f", amount))", isTotal: true)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        
                        // Payment Methods
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Payment Method")
                                .font(.headline)
                                .foregroundColor(.mint)
                            
                            VStack(spacing: 12) {
                                ForEach(paymentMethods, id: \.name) { method in
                                    Button(action: { selectedPaymentMethod = method.type }) {
                                        HStack {
                                            Image(systemName: method.icon)
                                                .foregroundColor(.mint)
                                            
                                            Text(method.name)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if selectedPaymentMethod == method.type {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Pay Button
                Button(action: {
                    guard !isProcessing else { return }
                    isProcessing = true
                    
                    Task {
                        do {
                            guard let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
                                  let patientId = UUID(uuidString: patientIdString),
                                  let hospitalId = UserDefaults.standard.string(forKey: "hospitalId"),
                                  let hospitalUUID = UUID(uuidString: hospitalId) else {
                                errorMessage = "Missing required information"
                                showError = true
                                isProcessing = false
                                return
                            }
                            
                            try await SupabaseController().bookLabTest(
                                patientId: patientId,
                                tests: selectedTests,
                                scheduledDate: preferredDate,
                                hospitalId: hospitalUUID
                            )
                            
                            await MainActor.run {
                                isProcessing = false
                                showConfirmation = true
                            }
                        } catch {
                            print("Error booking lab test:", error)
                            await MainActor.run {
                                errorMessage = "Failed to book lab test. Please try again."
                                showError = true
                                isProcessing = false
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Pay ₹\(String(format: "%.2f", amount))")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedPaymentMethod == nil ? Color.gray : Color.mint)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding()
                }
                .disabled(isProcessing)
            }
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .background(Color(.systemGroupedBackground))
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showConfirmation) {
                Button("OK") {
                    onComplete(true)
                    dismiss()
                }
            } message: {
                Text("Lab tests booked successfully!")
            }
        }
    }
    
    private func detailRow(title: String, value: String, isTotal: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(isTotal ? .headline : .body)
                .foregroundColor(isTotal ? .mint : .gray)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct PaymentConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let amount: Double
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            Circle()
                .fill(Color.mint)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
                .padding(.top, 40)
            
            // Success Message
            VStack(spacing: 8) {
                Text("Payment Successful")
                    .font(.title2)
                    .foregroundColor(.mint)
                
                Text("Your appointment has been confirmed.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            // Appointment Details Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Appointment Details")
                    .font(.headline)
                    .foregroundColor(.mint)
                
                VStack(spacing: 16) {
                    detailRow(title: "Hospital:", value: "Apollo")
                    detailRow(title: "Date & Time:", value: "Thursday, Apr 3, 2025 • 11:00 AM")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Payment Details Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Payment Details")
                    .font(.headline)
                    .foregroundColor(.mint)
                
                detailRow(title: "Appointment ID:", value: "5A780C26-AE60-4A19-AAC3-279A6BCFAD6D")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: { /* Show Invoice */ }) {
                    Text("View Invoice")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    onDone()
                    dismiss()
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationView {
        LabTestBookingView()
    }
}

// Add these models if not already in your DataModel.swift
//struct LabTestBooking: Identifiable, Codable {
//    let id: UUID
//    let patientId: String
//    let hospitalId: UUID
//    let tests: [String]
//    let scheduledDate: Date
//    var status: LabTestStatus
//    let notes: String
//    let createdAt: Date
//    var reportURL: String?
//}
//
//enum LabTestStatus: String, Codable {
//    case scheduled = "Scheduled"
//    case completed = "Completed"
//    case cancelled = "Cancelled"
//}

//enum LabTest: String, CaseIterable {
//    case bloodTest = "Blood Test"
//    case urineTest = "Urine Test"
//    case xRay = "X-Ray"
//    case mri = "MRI"
//    case ct = "CT Scan"
//    case ultrasound = "Ultrasound"
//} 
