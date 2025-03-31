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
            if let (hospital, adminName) = try await supabaseController.fetchHospitalAndAdmin() {
                print("Successfully fetched hospital:", hospital)
                await MainActor.run {
                    hospitalName = hospital.name
                    hospitalLocation = "\(hospital.city), \(hospital.state)"
                }
            } else {
                print("No hospital or admin found")
                await MainActor.run {
                    hospitalName = "Hospital"
                    hospitalLocation = "Location not found"
                    errorMessage = "Could not find hospital details"
                }
            }
        } catch {
            print("Error fetching hospital and admin:", error.localizedDescription)
            await MainActor.run {
                hospitalName = "Hospital"
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
