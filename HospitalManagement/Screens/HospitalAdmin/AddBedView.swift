//
//  AddBedView.swift
//  HospitalManagement
//
//  Created by Mariyo on 26/03/25.
//

import SwiftUI

struct AddBedView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @Environment(\.dismiss) private var dismiss
    
    // Add hospital ID state
    @State private var currentHospitalId: UUID?
    
    // Form state
    @State private var price: String = ""
    @State private var selectedType: BedType = .General
    @State private var isAvailable: Bool = true
    @State private var bedCount: String = ""
    
    // Alert state
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    
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
            .navigationTitle("Add Bed")
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
                        Task {
                            await addBed()
                        }
                    }
                    .foregroundColor(AppConfig.buttonColor)
                    .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Adding beds...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 10)
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
        .task {
            // Fetch the hospital ID when view appears
            do {
                if let (hospital, _) = try await supabaseController.fetchHospitalAndAdmin() {
                    currentHospitalId = hospital.id
                }
            } catch {
                alertMessage = "Failed to fetch hospital information"
                isSuccess = false
                showAlert = true
            }
        }
    }
    
    private func addBed() async {
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
        
        guard let hospitalId = currentHospitalId else {
            alertMessage = "Hospital information not available"
            isSuccess = false
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Create beds array
            var beds: [Bed] = []
            for _ in 1...numberOfBeds {
                let newBed = Bed(
                    id: UUID(),
                    hospitalId: hospitalId, // Set the hospital ID
                    price: priceValue,
                    type: selectedType,
                    isAvailable: isAvailable
                )
                beds.append(newBed)
            }
            
            // Add beds to Supabase with hospital ID
            try await supabaseController.addBeds(beds: beds, hospitalId: hospitalId)
            
            // Show success alert
            isSuccess = true
            let unitText = numberOfBeds == 1 ? "bed" : "beds"
            alertMessage = "\(numberOfBeds) \(unitText) added successfully"
        } catch {
            isSuccess = false
            alertMessage = "Failed to add beds: \(error.localizedDescription)"
        }
        
        isLoading = false
        showAlert = true
    }
}

#Preview {
    AddBedView()
}
