import SwiftUI

struct LabTestBookingView: View {
    @Environment(\.dismiss) private var dismiss
    
    // State variables
    @State private var selectedTests: [labTest.labTestName] = []
    @State private var preferredDate = Date()
    @State private var preferredTime = Date()
    @State private var additionalNotes = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    // Simplified time slots
    private var timeSlots: [Date] {
        let calendar = Calendar.current
        let now = Date()
        var slots: [Date] = []
        
        for hour in 9...17 {
            if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) {
                slots.append(date)
            }
        }
        return slots
    }
    
    // Grid layout
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Test Selection Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Tests")
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(labTest.labTestName.allCases, id: \.self) { test in
                            TestSelectionCard(
                                testName: test,
                                isSelected: selectedTests.contains(test),
                                action: {
                                    toggleTest(test)
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Date Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Date")
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    DatePicker(
                        "Preferred Date",
                        selection: $preferredDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Time Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Time")
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(timeSlots, id: \.self) { slot in
                                TimeSlotButton(
                                    time: slot,
                                    isSelected: isTimeSlotSelected(slot),
                                    action: { selectTimeSlot(slot) }
                                )
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Additional Notes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Additional Notes")
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    TextEditor(text: $additionalNotes)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Book Button
                bookButton
            }
            .padding()
        }
        .background(AppConfig.backgroundColor)
        .navigationTitle("Book Lab Test")
        .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
            Button("OK") {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var bookButton: some View {
        Button(action: handleBooking) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text("Book Lab Test")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedTests.isEmpty ? Color.gray : AppConfig.buttonColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedTests.isEmpty || isLoading)
        .padding(.horizontal)
    }
    
    // Helper functions
    private func toggleTest(_ test: labTest.labTestName) {
        if selectedTests.contains(test) {
            selectedTests.removeAll { $0 == test }
        } else {
            selectedTests.append(test)
        }
    }
    
    private func isTimeSlotSelected(_ slot: Date) -> Bool {
        Calendar.current.compare(preferredTime, to: slot, toGranularity: .hour) == .orderedSame
    }
    
    private func selectTimeSlot(_ slot: Date) {
        preferredTime = slot
    }
    
    private func handleBooking() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSuccess = true
            alertMessage = "Lab test booking created successfully!"
            showAlert = true
            isLoading = false
        }
    }
}

// Helper Views
struct TestSelectionCard: View {
    let testName: labTest.labTestName
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "cross.vial.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : AppConfig.buttonColor)
                
                Text(testName.rawValue)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : AppConfig.fontColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppConfig.buttonColor : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct TimeSlotButton: View {
    let time: Date
    let isSelected: Bool
    let action: () -> Void
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        Button(action: action) {
            Text(timeFormatter.string(from: time))
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppConfig.buttonColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : AppConfig.fontColor)
                .cornerRadius(8)
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
