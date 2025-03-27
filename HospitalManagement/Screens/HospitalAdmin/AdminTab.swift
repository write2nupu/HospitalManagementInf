//
//  AdminTab.swift
//  HospitalManagement
//
//  Created by sudhanshu on 25/03/25.
//

import SwiftUI
struct AdminTabView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @State private var showAdminProfile = false
    
    var body: some View {
        NavigationStack {
            TabView {
                AdminHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                BedView()
                    .tabItem {
                        Label("Services", systemImage: "wrench.adjustable.fill")
                    }
                
                BillingView()
                    .tabItem {
                        Label("Billing", systemImage: "indianrupeesign.gauge.chart.lefthalf.righthalf")
                    }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Hospital Management")
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


struct Services: View {
    var body: some View {
        VStack {
            Text("Doctors List")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
        }
 
    }
}



#Preview {
    let mockViewModel = HospitalManagementViewModel()
    return AdminTabView()
        .environmentObject(mockViewModel)
   
}
