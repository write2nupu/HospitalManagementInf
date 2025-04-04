//
//  BookedBedView.swift
//  HospitalManagement
//
//  Created by Nupur on 26/03/25.
//

import SwiftUI

struct CurrentBedBookingView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var bookedBeds: [BedBookingWithDetails] = []
    @State private var selectedHospital: Hospital?
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                bookingCardView
                
                if isLoading {
                    ProgressView("Loading booked beds...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if bookedBeds.isEmpty {
                        emptyBookingsView
                    } else {
                        bookedBedsListView
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Bed Booking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInitialData()
        }
        .refreshable {
            await loadInitialData()
        }
    }
    
    private var bookingCardView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.buttonColor.opacity(0.1))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Need a Bed?")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    bookNowButton
                }
                .padding(.leading, 25)
                
                Spacer()
                
                Image("BedBookingImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .padding(.trailing, 25)
            }
            .padding(.vertical)
        }
        .frame(height: 180)
        .padding(.horizontal)
    }
    
    private var bookNowButton: some View {
        Group {
            if let hospital = selectedHospital {
                NavigationLink(destination: BedBookingView(hospital: hospital)) {
                    Text("Book Now")
                        .fontWeight(.semibold)
                        .foregroundColor(AppConfig.backgroundColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppConfig.buttonColor)
                        .cornerRadius(10)
                }
            } else {
                Text("Loading hospital...")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var bookedBedsListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Bookings")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(bookedBeds) { booking in
                bookingCard(for: booking)
            }
        }
    }
    
    private var emptyBookingsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bed.double")
                .font(.system(size: 50))
                .foregroundColor(AppConfig.buttonColor)
            
            Text("No Active Bookings")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Your booked beds will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .padding()
    }
    
    private func bookingCard(for booking: BedBookingWithDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double")
                    .font(.title3)
                    .foregroundColor(AppConfig.buttonColor)
                
                Text(booking.bedType.rawValue)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                bookingDateRow(title: "Check In", date: booking.startDate)
                bookingDateRow(title: "Check Out", date: booking.endDate)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.buttonColor.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    private func bookingDateRow(title: String, date: Date) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatDate(date))
                .foregroundColor(.primary)
        }
        .font(.subheadline)
    }
    
    private func loadInitialData() async {
        isLoading = true
        do {
            // Load hospital
            let hospitals = await supabaseController.fetchHospitals()
            if let firstHospital = hospitals.first {
                selectedHospital = firstHospital
            }
            
            // Load booked beds for the current patient
            if let patientId = UserDefaults.standard.string(forKey: "currentPatientId"),
               let patientUUID = UUID(uuidString: patientId) {
                bookedBeds = try await supabaseController.getBookingsByPatientId(patientId: patientUUID)
            } else {
                errorMessage = "Please log in to view your bookings."
            }
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Preview
struct CurrentBedBookingView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentBedBookingView()
    }
}
