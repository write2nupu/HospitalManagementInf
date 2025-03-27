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
    
    // Computed properties to get bed statistics
    private var allBeds: [Bed] { beds }
    private var availableBeds: [Bed] { beds.filter { $0.isAvailable! } }
    private var bedsByType: [BedType: [Bed]] {
        Dictionary(grouping: beds) { $0.type }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if let error = errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await loadData()
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // MARK: - Beds Overview Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Beds")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showAddBed = true
                                    } label: {
                                        Label("Add Bed", systemImage: "plus.circle.fill")
                                            .font(.subheadline)
                                            .foregroundColor(.mint)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Beds summary card
                                HStack(spacing: 20) {
                                    BedStatCard(
                                        title: "Total Beds",
                                        count: allBeds.count,
                                        iconName: "bed.double.fill",
                                        iconColor: .mint
                                    )
                                    
                                    BedStatCard(
                                        title: "Available",
                                        count: availableBeds.count,
                                        iconName: "checkmark.circle.fill",
                                        iconColor: .green
                                    )
                                }
                                .padding(.horizontal)
                            }
                            
                            // MARK: - Categories Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Categories")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        // General Beds Card
                                        BedCategoryCard(
                                            title: "General",
                                            total: bedsByType[.General]?.count ?? 0,
                                            available: bedsByType[.General]?.filter { $0.isAvailable == true }.count ?? 0,
                                            iconName: "bed.double",
                                            iconColor: .blue
                                        )
                                        
                                        // ICU Beds Card
                                        BedCategoryCard(
                                            title: "ICU",
                                            total: bedsByType[.ICU]?.count ?? 0,
                                            available: bedsByType[.ICU]?.filter { $0.isAvailable == true }.count ?? 0,
                                            iconName: "waveform.path.ecg",
                                            iconColor: .red
                                        )
                                        
                                        // Personal Beds Card
                                        BedCategoryCard(
                                            title: "Personal",
                                            total: bedsByType[.Personal]?.count ?? 0,
                                            available: bedsByType[.Personal]?.filter { $0.isAvailable == true }.count ?? 0,
                                            iconName: "person.fill",
                                            iconColor: .purple
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
                                    .padding(.horizontal)
                                
                                if recentBookings.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "bed.double")
                                            .font(.system(size: 40))
                                            .foregroundColor(.mint.opacity(0.3))
                                        Text("No recent bookings")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Booked beds will appear here")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                } else {
                                    VStack(spacing: 12) {
                                        // Headers
                                        HStack {
                                            Text("Patient")
                                                .fontWeight(.semibold)
                                                .frame(width: 130, alignment: .leading)
                                            
                                            Text("Bed Type")
                                                .fontWeight(.semibold)
                                                .frame(width: 100, alignment: .leading)
                                            
                                            Spacer()
                                            
                                            Text("Amount")
                                                .fontWeight(.semibold)
                                                .frame(width: 80, alignment: .trailing)
                                        }
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                        .padding(.horizontal)
                                        
                                        // Bookings list
                                        ForEach(recentBookings) { booking in
                                            HStack {
                                                Text(booking.patientName)
                                                    .fontWeight(.medium)
                                                    .frame(width: 130, alignment: .leading)
                                                    .lineLimit(1)
                                                
                                                Text(booking.bedType.rawValue)
                                                    .frame(width: 100, alignment: .leading)
                                                
                                                Spacer()
                                                
                                                Text("₹\(booking.amount)")
                                                    .fontWeight(.medium)
                                                    .frame(width: 80, alignment: .trailing)
                                            }
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(10)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Bed Management")
            .sheet(isPresented: $showAddBed) {
                AddBedView()
            }
            .task {
                await loadData()
            }
        }
    }
    
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let bedsTask = supabaseController.fetchAllBeds()
            async let bookingsTask = supabaseController.getRecentBedBookings()
            async let statsTask = supabaseController.getBedStatistics()
            
            let (fetchedBeds, fetchedBookings, fetchedStats) = try await (bedsTask, bookingsTask, statsTask)
            
            beds = fetchedBeds
            recentBookings = fetchedBookings
            bedStats = fetchedStats
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views
struct BedStatCard: View {
    let title: String
    let count: Int
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct BedCategoryCard: View {
    let title: String
    let total: Int
    let available: Int
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                Spacer()
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(total)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(available)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .frame(width: 180, height: 140)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Helper Models
struct BedBookingWithDetails: Identifiable {
    let id: UUID
    let patientName: String
    let bedType: BedType
    let amount: Int
    
    // Initialize from the existing data model
    init(booking: BedBooking, patient: Patient, bed: Bed) {
        self.id = booking.id
        self.patientName = patient.fullname
        self.bedType = bed.type
        self.amount = bed.price
    }
    
    // Convenience initializer for preview or testing
    init(id: UUID, patientName: String, bedType: BedType, amount: Int) {
        self.id = id
        self.patientName = patientName
        self.bedType = bedType
        self.amount = amount
    }
}

#Preview {
    BedView()
}
