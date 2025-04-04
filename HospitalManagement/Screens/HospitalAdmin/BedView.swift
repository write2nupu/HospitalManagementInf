//
//  BedBooking.swift
//  HospitalManagement
//
//  Created by Mariyo on 25/03/25.
//

import Foundation
import SwiftUI

struct BedView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    @State private var showAddBed = false
    @State private var beds: [Bed] = []
    @State private var recentBookings: [BedBookingWithDetails] = []
    @State private var bedStats: (total: Int, available: Int, byType: [BedType: (total: Int, available: Int)]) = (0, 0, [:])
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    // Computed properties to get bed statistics
    private var allBeds: [Bed] { beds }
    private var availableBeds: [Bed] { beds.filter { $0.isAvailable ?? false } }
    private var bedsByType: [BedType: [Bed]] {
        Dictionary(grouping: beds) { $0.type }
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView("Loading...")
                        .padding(.top, 50)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 24) {
                    // MARK: - Beds Overview Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Beds")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppConfig.fontColor)
                            
                            Spacer()
                            
                            if errorMessage != nil {
                                Button {
                                    Task {
                                        await loadData()
                                    }
                                } label: {
                                    Label("Retry", systemImage: "arrow.clockwise")
                                        .font(.subheadline)
                                        .foregroundColor(AppConfig.pendingColor)
                                }
                            }
                            
                            Button {
                                showAddBed = true
                            } label: {
                                Label("Add Bed", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(AppConfig.buttonColor)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Error banner if needed
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppConfig.redColor)
                                Text("Error: \(error)")
                                    .font(.caption)
                                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
                                Spacer()
                            }
                            .padding()
                            .background(AppConfig.redColor.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        
                        // Beds summary cards
                        VStack(spacing: 16) {
                            BedStatCard(
                                title: "Total Beds",
                                count: allBeds.count,
                                iconName: "bed.double.fill",
                                iconColor: AppConfig.buttonColor
                            )
                            
                            BedStatCard(
                                title: "Available",
                                count: availableBeds.count,
                                iconName: "checkmark.circle.fill",
                                iconColor: AppConfig.approvedColor
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // General Beds Card
                                BedCategoryCard(
                                    title: "General",
                                    total: bedsByType[.General]?.count ?? 0,
                                    available: bedsByType[.General]?.filter { $0.isAvailable ?? false }.count ?? 0,
                                    iconName: "bed.double",
                                    iconColor: AppConfig.buttonColor
                                )
                                
                                // ICU Beds Card
                                BedCategoryCard(
                                    title: "ICU",
                                    total: bedsByType[.ICU]?.count ?? 0,
                                    available: bedsByType[.ICU]?.filter { $0.isAvailable ?? false }.count ?? 0,
                                    iconName: "waveform.path.ecg",
                                    iconColor: AppConfig.redColor
                                )
                                
                                // Personal Beds Card
                                BedCategoryCard(
                                    title: "Personal",
                                    total: bedsByType[.Personal]?.count ?? 0,
                                    available: bedsByType[.Personal]?.filter { $0.isAvailable ?? false }.count ?? 0,
                                    iconName: "person.fill",
                                    iconColor: AppConfig.pendingColor
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // MARK: - Recent Bookings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recents")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        if recentBookings.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bed.double")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppConfig.buttonColor.opacity(0.5))
                                Text("No recent bookings")
                                    .font(.headline)
                                    .foregroundColor(AppConfig.fontColor)
                                Text("Booked beds will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(AppConfig.cardColor)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(recentBookings) { booking in
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(booking.patientName)
                                                .font(.headline)
                                                .foregroundColor(AppConfig.fontColor)
                                            Text(booking.bedType.rawValue)
                                                .font(.subheadline)
                                                .foregroundColor(AppConfig.fontColor.opacity(0.7))
                                        }
                                        Spacer()
                                        Text(formatDate(booking.startDate))
                                            .font(.caption)
                                            .foregroundColor(AppConfig.approvedColor)
                                    }
                                    .padding()
                                    .background(AppConfig.cardColor)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .background(AppConfig.backgroundColor.ignoresSafeArea())
        .navigationTitle("Bed Management")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showAddBed) {
            AddBedView()
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get hospital ID from UserDefaults
            guard let hospitalIdString = UserDefaults.standard.string(forKey: "hospitalId"),
                  let hospitalId = UUID(uuidString: hospitalIdString) else {
                errorMessage = "Could not determine hospital ID"
                isLoading = false
                return
            }
            
            // Load beds data
            do {
                beds = try await supabaseController.fetchAllBeds(hospitalId: hospitalId)
            } catch {
                print("Error loading beds: \(error.localizedDescription)")
                errorMessage = "Couldn't load beds: \(error.localizedDescription)"
                beds = []
            }
            
            // Load bookings data with hospital ID filter
            do {
                print("Fetching recent bed bookings for hospital ID: \(hospitalId)")
                recentBookings = try await supabaseController.getRecentBedBookings(hospitalId: hospitalId, limit: 15)
                print("Successfully fetched \(recentBookings.count) recent bookings")
            } catch {
                print("Error loading bookings: \(error.localizedDescription)")
                errorMessage = "Couldn't load bookings: \(error.localizedDescription)"
                recentBookings = []
            }
            
            // Load statistics data
            do {
                bedStats = try await supabaseController.getBedStatistics(hospitalId: hospitalId)
            } catch {
                print("Error loading bed statistics: \(error.localizedDescription)")
                // Use fallback stats based on available beds
                let total = beds.count
                let available = beds.filter { $0.isAvailable ?? false }.count
                var statsByType: [BedType: (total: Int, available: Int)] = [:]
                
                for type in [BedType.General, BedType.ICU, BedType.Personal] {
                    let bedsOfType = beds.filter { $0.type == type }
                    let totalOfType = bedsOfType.count
                    let availableOfType = bedsOfType.filter { $0.isAvailable ?? false }.count
                    statsByType[type] = (total: totalOfType, available: availableOfType)
                }
                
                bedStats = (total: total, available: available, byType: statsByType)
            }
            
        } 
        
        isLoading = false
    }
    
    // Helper functions for date formatting and comparison
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func isPastDate(_ date: Date) -> Bool {
        return date < Date()
    }
    
    private func isFutureDate(_ date: Date) -> Bool {
        return date > Date()
    }
}

// MARK: - Supporting Views
struct BedStatCard: View {
    let title: String
    let count: Int
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor.opacity(0.7))
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppConfig.fontColor)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppConfig.cardColor)
        .cornerRadius(16)
        .shadow(color: AppConfig.shadowColor, radius: 5)
    }
}

struct BedCategoryCard: View {
    let title: String
    let total: Int
    let available: Int
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon and Title
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 50, height: 50)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
            }
            
            // Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                    Text("\(total)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.fontColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                    Text("\(available)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.approvedColor)
                }
            }
        }
        .padding()
        .frame(width: 200)
        .background(AppConfig.cardColor)
        .cornerRadius(16)
        .shadow(color: AppConfig.shadowColor, radius: 5)
    }
}

// MARK: - Helper Models
struct BedBookingWithDetails: Identifiable {
    let id: UUID
    let patientName: String
    let bedType: BedType
    let amount: Int
    let startDate: Date
    let endDate: Date
    
    // Initialize from the existing data model
    init(booking: BedBooking, patient: Patient, bed: Bed) {
        self.id = booking.id
        self.patientName = patient.fullname
        self.bedType = bed.type
        self.amount = bed.price
        self.startDate = booking.startDate
        self.endDate = booking.endDate
    }
    
    // Convenience initializer for preview or testing
    init(id: UUID, patientName: String, bedType: BedType, amount: Int, startDate: Date = Date(), endDate: Date = Date()) {
        self.id = id
        self.patientName = patientName
        self.bedType = bedType
        self.amount = amount
        self.startDate = startDate
        self.endDate = endDate
    }
}

#Preview {
    BedView()
}
