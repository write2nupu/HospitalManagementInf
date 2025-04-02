//
//  MedicineSelectionView.swift
//  HospitalManagement
//
//  Created by Jashan on 27/03/25.
//

import Foundation


import SwiftUI

struct MedicineSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var prescribedMedicines: [PrescribedMedicine]
    
    @State private var searchText = ""
    @State private var searchResults: [MedicineResponse] = []
    @State private var isSearching = false
    @State private var selectedMedicine: MedicineResponse?
    @State private var showingDosageSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar - Fixed at top
                MedicineSearchBar(text: $searchText, isSearching: $isSearching)
                    .background(Color.white)
                    .onChange(of: searchText) {_, newValue in
                        if !newValue.isEmpty && newValue.count >= 2 {
                            searchMedicines(query: newValue)
                        } else {
                            searchResults = []
                        }
                    }
                
                // Content Area
                ScrollView {
                    VStack(spacing: 0) {
                        if isSearching {
                            ProgressView("Searching...")
                                .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                if searchResults.isEmpty && !searchText.isEmpty {
                                    NoResultsView()
                                } else {
                                    ForEach(searchResults) { medicine in
                                        MedicineCard(medicine: medicine) {
                                            print("Selected medicine: \(medicine.name)")
                                            selectedMedicine = medicine
                                            showingDosageSheet = true
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Add Medicine")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .sheet(isPresented: $showingDosageSheet) {
                if let medicine = selectedMedicine {
                    DosageSelectionSheet(
                        medicine: medicine,
                        prescribedMedicines: $prescribedMedicines,
                        isPresented: $showingDosageSheet
                    )
                }
            }
        }
    }
    
    private func searchMedicines(query: String) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode query: \(query)")
            return
        }
        
        let urlString = "https://hms-server-4kjy.onrender.com/search?name=\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        print("Searching for: \(query)")
        print("URL: \(urlString)")
        
        isSearching = true
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
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
                    print("Decoding error: \(error)")
                    searchResults = []
                }
            }
        }
        task.resume()
    }
}

// New view for no results
struct NoResultsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No medicines found")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Try searching with a different name")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// Updated MedicineCard with better styling
struct MedicineCard: View {
    let medicine: MedicineResponse
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(medicine.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Tap to add to prescription")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct MedicineSearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search medicines...", text: $text)
                    .autocapitalization(.none)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
    }
}

struct DosageSelectionSheet: View {
    let medicine: MedicineResponse
    @Binding var prescribedMedicines: [PrescribedMedicine]
    @Binding var isPresented: Bool
    
    @State private var selectedDosage = DosageOption.oneDaily
    @State private var selectedDuration = DurationOption.sevenDays
    @State private var customTiming = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Details")) {
                    Text(medicine.name)
                        .font(.headline)
                }
                
                Section(header: Text("Dosage")) {
                    Picker("Dosage", selection: $selectedDosage) {
                        ForEach(DosageOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                
                Section(header: Text("Duration")) {
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(DurationOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                
                Section(header: Text("Additional Instructions")) {
                    TextField("Optional timing instructions", text: $customTiming)
                }
            }
            .navigationTitle("Prescription Details")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Add") {
                    addMedicine()
                    isPresented = false
                }
            )
        }
    }
    
    private func addMedicine() {
        
        let prescribed = PrescribedMedicine(
            medicine: medicine,
            dosage: selectedDosage.rawValue,
            duration: selectedDuration.rawValue,
            timing: customTiming
        )
        //PrescribedMedicine(medicine: <#T##MedicineResponse#>, dosage: <#T##String#>, duration: <#T##String#>, timing: <#T##String#>)
        
        prescribedMedicines.append(prescribed)
    }
}
