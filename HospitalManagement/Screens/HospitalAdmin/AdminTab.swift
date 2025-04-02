//
//  AdminTab.swift
//  HospitalManagement
//
//  Created by sudhanshu on 25/03/25.
//

import SwiftUI

struct AdminTabView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var showAdminProfile = false
    @State private var hospitalName: String = "Loading..."
    @State private var hospitalLocation: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            TabView {
                AdminHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                AnalyticsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                
                BedView()
                    .tabItem {
                        Label("Bed", systemImage: "bed.double.circle")
                    }
                
                BillingView()
                    .tabItem {
                        Label("Billing", systemImage: "indianrupeesign.gauge.chart.lefthalf.righthalf")
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdminProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.mint)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 4) {
                        Text(hospitalName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(hospitalLocation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .sheet(isPresented: $showAdminProfile) {
                AdminProfileView()
            }
            .task {
                await fetchHospitalName()
            }
        }
    }
    
    private func fetchHospitalName() async {
        do {
            // Get the hospital ID of the logged-in admin from UserDefaults
            if let hospitalIdString = UserDefaults.standard.string(forKey: "hospitalId"),
               let hospitalId = UUID(uuidString: hospitalIdString) {
                print("Fetching hospital with ID: \(hospitalId)")
                
                // Fetch the specific hospital by ID
                let hospitals: [Hospital] = try await supabaseController.client
                    .from("Hospital")
                    .select("*")
                    .eq("id", value: hospitalId.uuidString)
                    .execute()
                    .value
                
                if let hospital = hospitals.first {
                    print("Successfully fetched hospital for logged-in admin:", hospital)
                    await MainActor.run {
                        hospitalName = hospital.name
                        hospitalLocation = "\(hospital.city), \(hospital.state)"
                    }
                } else {
                    print("No hospital found with ID: \(hospitalId)")
                    await MainActor.run {
                        hospitalName = "Your Hospital"
                        hospitalLocation = "Location not found"
                        errorMessage = "Could not find hospital details"
                    }
                }
            } else {
                print("No hospital ID found for logged-in admin")
                await MainActor.run {
                    hospitalName = "Your Hospital"
                    hospitalLocation = "Location not found"
                    errorMessage = "Could not find hospital ID"
                }
            }
        } catch {
            print("Error fetching hospital details:", error.localizedDescription)
            await MainActor.run {
                hospitalName = "Your Hospital"
                hospitalLocation = "Location not found"
                errorMessage = "Error loading hospital details"
            }
        }
    }
}

#Preview {
    let mockViewModel = HospitalManagementViewModel()
    return AdminTabView()
        .environmentObject(mockViewModel)
}


