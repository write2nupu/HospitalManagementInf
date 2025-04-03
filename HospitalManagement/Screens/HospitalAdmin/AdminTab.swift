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
            NavigationStack {
                AdminHomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.fill")
            }
            
            NavigationStack {
                BedView()
            }
            .tabItem {
                Label("Bed", systemImage: "bed.double.circle")
            }
            
            NavigationStack {
                BillingView()
            }
            .tabItem {
                Label("Billing", systemImage: "indianrupeesign.gauge.chart.lefthalf.righthalf")
            }
        }
        .tabViewStyle(DefaultTabViewStyle())
        .onAppear {
            // Hide the back button appearance in tab views
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    let mockViewModel = HospitalManagementViewModel()
    return AdminTabView()
        .environmentObject(mockViewModel)
}
