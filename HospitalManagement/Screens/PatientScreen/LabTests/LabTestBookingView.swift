//
//  LabTestBookingView.swift
//  HospitalManagement
//
//  Created by Nikhil Gupta on 03/04/25.
//

import Foundation
import SwiftUI

struct LabTestBookingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseController()
    
    let prescription: PrescriptionData
    
    @State private var selectedTests: [LabTest.LabTestName] = []
    @State private var preferredDate = Date()
    @State private var showTestSelection = false
    @State private var showPayment = false
    @State private var isLoading = false
    @State private var tempSelectedTests: [LabTest.LabTestName] = []
    
    // Break down test prices into a function for better compiler performance
    private func getTestPrice(_ test: LabTest.LabTestName) -> Double {
        test.price
    }
    
    private var totalAmount: Double {
        selectedTests.reduce(0) { $0 + getTestPrice($1) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                prescriptionInfoSection
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
            TestSelectionView(selectedTests: $selectedTests, prescriptionTests: prescription.labTests ?? [])
        }
        .sheet(isPresented: $showPayment) {
            LabTestPaymentView(
                amount: totalAmount,
                selectedTests: selectedTests,
                preferredDate: preferredDate,
                prescriptionId: prescription.id,
                onComplete: { success in
                    if success {
                        dismiss()
                    }
                }
            )
        }
        .onAppear {
            // Convert prescription tests to LabTestName enum values and pre-select them
            if let tests = prescription.labTests {
                selectedTests = tests.compactMap { testName in
                    LabTest.LabTestName.allCases.first { $0.rawValue == testName }
                }
                // Also set them as temporary selected tests
                tempSelectedTests = selectedTests
            }
        }
    }
    
    private var prescriptionInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prescription Details")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Diagnosis:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(prescription.diagnosis)
                    .font(.body)
                
                if let tests = prescription.labTests {
                    Text("Recommended Tests:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    ForEach(tests, id: \.self) { test in
                        Text("• \(test)")
                            .font(.body)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
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
    
    private func removeTest(_ test: LabTest.LabTestName) {
        selectedTests.removeAll { $0 == test }
    }
}

struct TestSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTests: [LabTest.LabTestName]
    let prescriptionTests: [String]
    @State private var tempSelectedTests: [LabTest.LabTestName] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(LabTest.LabTestName.allCases, id: \.self) { test in
                    HStack {
                        Text(test.rawValue)
                        Spacer()
                        if tempSelectedTests.contains(test) {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppConfig.buttonColor)
                        }
                        if prescriptionTests.contains(test.rawValue) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 14))
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

#Preview {
    NavigationView {
        LabTestBookingView(prescription: PrescriptionData(
            id: UUID(),
            patientId: UUID(),
            doctorId: UUID(),
            diagnosis: "Sample diagnosis",
            labTests: ["Complete Blood Count", "Blood Sugar Test"],
            additionalNotes: nil,
            medicineName: nil,
            medicineDosage: nil,
            medicineDuration: nil
        ))
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
