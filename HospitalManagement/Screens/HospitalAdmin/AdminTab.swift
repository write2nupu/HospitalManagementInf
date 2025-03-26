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
        TabView {
            AdminHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            Services()
                .tabItem {
                    Label("Services", systemImage: "wrench.adjustable.fill")
                }
            
            BillingView()
                .tabItem {
                    Label("Billing", systemImage: "indianrupeesign.gauge.chart.lefthalf.righthalf")
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
