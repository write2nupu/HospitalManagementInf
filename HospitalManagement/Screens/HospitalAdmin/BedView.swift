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
        NavigationStack {
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
                                
                                Spacer()
                                
                                if errorMessage != nil {
                                    Button {
                                        Task {
                                            await loadData()
                                        }
                                    } label: {
                                        Label("Retry", systemImage: "arrow.clockwise")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Button {
                                    showAddBed = true
                                } label: {
                                    Label("Add Bed", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.mint)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Error banner if needed
                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Error: \(error)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                            
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
                                        available: bedsByType[.General]?.filter { $0.isAvailable ?? false }.count ?? 0,
                                        iconName: "bed.double",
                                        iconColor: .blue
                                    )
                                    
                                    // ICU Beds Card
                                    BedCategoryCard(
                                        title: "ICU",
                                        total: bedsByType[.ICU]?.count ?? 0,
                                        available: bedsByType[.ICU]?.filter { $0.isAvailable ?? false }.count ?? 0,
                                        iconName: "waveform.path.ecg",
                                        iconColor: .red
                                    )
                                    
                                    // Personal Beds Card
                                    BedCategoryCard(
                                        title: "Personal",
                                        total: bedsByType[.Personal]?.count ?? 0,
                                        available: bedsByType[.Personal]?.filter { $0.isAvailable ?? false }.count ?? 0,
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
                                    // Bookings list
                                    ForEach(recentBookings) { booking in
                                        HStack(spacing: 12) {
                                            // Patient info
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(booking.patientName)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                Text(booking.bedType.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            // Date info
                                            VStack(alignment: .trailing, spacing: 4) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "calendar.badge.plus")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                    Text(formatDate(booking.startDate))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "calendar.badge.minus")
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                    Text(formatDate(booking.endDate))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Bed Management")
            .sheet(isPresented: $showAddBed) {
                AddBedView()
            }
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .alert("Data Loading Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
                Button("Retry") {
                    Task {
                        await loadData()
                    }
                }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
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
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            showErrorAlert = true
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
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text("\(available)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .frame(width: 200, height: 140)
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
