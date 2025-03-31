//
//  AdminTab.swift
//  HospitalManagement
//
//  Created by sudhanshu on 25/03/25.
//

import SwiftUI
struct AdminTabView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
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
            .navigationBarBackButtonHidden(true)
        }
    }
}


struct Services: View {
    @State private var showAdminProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Content goes here
                    Text("Services Content")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Doctors List")
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
            .sheet(isPresented: $showAdminProfile) {
                AdminProfileView()
            }
        }
    }
}



#Preview {
    let mockViewModel = HospitalManagementViewModel()
    return AdminTabView()
        .environmentObject(mockViewModel)
   
}
