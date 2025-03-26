//
//  AddBedView.swift
//  HospitalManagement
//
//  Created by Mariyo on 26/03/25.
//

import SwiftUI

struct AddBedView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var price: String = ""
    @State private var selectedType: BedType = .General
    @State private var isAvailable: Bool = true
    @State private var bedCount: String = ""
    
    // Alert state
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    // Manually define available bed types since BedType doesn't conform to CaseIterable
    private let bedTypes: [BedType] = [.General, .ICU, .Personal]
    
    var body: some View {
        NavigationStack {
            Form {
                // Bed Type Section
                Section(header: Text("Bed Information")) {
                    HStack {
                        Text("Bed Type")
                        Spacer()
                        Picker("", selection: $selectedType) {
                            ForEach(bedTypes, id: \.self) { type in
                                Text(type.rawValue)
                                    .tag(type)
                            }
                        }
                    }
                    
                    // Price Field
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("Enter amount", text: $price)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // Bed Count Field
                    HStack {
                        Text("Number of Beds")
                        Spacer()
                        TextField("Enter quantity", text: $bedCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Availability Section
//                Section(header: Text("Status")) {
//                    Toggle("Available for Booking", isOn: $isAvailable)
//                }
            }
            .navigationTitle("Add New Bed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppConfig.buttonColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addBed()
                    }
                    .foregroundColor(AppConfig.buttonColor)
                }
            }
            .alert(isPresented: $showAlert) {
                if isSuccess {
                    return Alert(
                        title: Text("Success"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK")) {
                            dismiss()
                        }
                    )
                } else {
                    return Alert(
                        title: Text("Error"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    private func addBed() {
        // Validate inputs
        guard let priceValue = Int(price), priceValue > 0 else {
            alertMessage = "Please enter a valid price"
            isSuccess = false
            showAlert = true
            return
        }
        
        guard let numberOfBeds = Int(bedCount), numberOfBeds > 0 else {
            alertMessage = "Please enter a valid number of beds"
            isSuccess = false
            showAlert = true
            return
        }
        
        // Create beds
        for _ in 1...numberOfBeds {
            let newBed = Bed(
                id: UUID(),
                hospitalId: nil, // Replace with actual hospital ID when implemented
                price: priceValue,
                type: selectedType,
                isAvailable: isAvailable
            )
            
            // Add bed to viewModel (you'll need to implement this function in your viewModel)
            // viewModel.addBed(newBed)
            
            print("New bed created: \(newBed)")
        }
        
        // Show success alert
        isSuccess = true
        let unitText = numberOfBeds == 1 ? "bed" : "beds"
        alertMessage = "\(numberOfBeds) \(unitText) added successfully"
        showAlert = true
    }
}

#Preview {
    AddBedView()
}
