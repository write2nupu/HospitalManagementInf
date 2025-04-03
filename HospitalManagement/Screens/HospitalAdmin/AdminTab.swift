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
        .tint(AppConfig.buttonColor)
        .onAppear {
            // Hide the back button appearance in tab views
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(AppConfig.backgroundColor)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(AppConfig.fontColor)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppConfig.fontColor)]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().tintColor = UIColor(AppConfig.buttonColor)
        }
    }
}

#Preview {
    let mockViewModel = HospitalManagementViewModel()
    return AdminTabView()
        .environmentObject(mockViewModel)
}
