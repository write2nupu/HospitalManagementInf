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
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                bookingCardView
                bookedSectionTitle
                bookedBedsContent
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
    }
    
    private var bookingCardView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .padding(.horizontal)
                .frame(height: 190)
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Need a Bed?")
                        .font(.title3)
                        .bold()
                        .padding(.leading, 30)
                    
                    bookNowButton
                }
                Spacer()
                Image("BedBookingImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .padding(.trailing, 40)
            }
            .padding()
        }
    }
    
    private var bookNowButton: some View {
        Group {
            if let hospital = selectedHospital {
                NavigationLink(destination: BedBookingView(hospital: hospital)) {
                    Text("Book Now")
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: 150)
                        .background(Color.mint)
                        .cornerRadius(8)
                        .padding(.leading, 16)
                }
            } else {
                Text("Loading hospital...")
                    .foregroundColor(.gray)
                    .padding(.leading, 16)
            }
        }
    }
    
    private var bookedSectionTitle: some View {
        Text("Booked")
            .font(.title2)
            .bold()
            .padding(.horizontal, 20)
    }
    
    private var bookedBedsContent: some View {
        Group {
            if isLoading {
                ProgressView("Loading booked beds...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if bookedBeds.isEmpty {
                emptyBookingsView
            } else {
                bookedBedsListView
            }
        }
    }
    
    private var emptyBookingsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bed.double")
                .font(.system(size: 40))
                .foregroundColor(.mint.opacity(0.3))
            Text("No beds booked")
                .font(.headline)
            Text("Your booked beds will appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var bookedBedsListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(bookedBeds) { booking in
                    bookingCard(for: booking)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func bookingCard(for booking: BedBookingWithDetails) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.mint.opacity(0.1))
            .padding(.horizontal)
            .frame(height: 100)
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bed Type: \(booking.bedType.rawValue)")
                        .font(.headline)
                    Text("Check In: \(formatDate(booking.startDate))")
                        .font(.body)
                    Text("Check Out: \(formatDate(booking.endDate))")
                        .font(.body)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                , alignment: .leading
            )
    }
    
    private func loadInitialData() async {
        isLoading = true
        do {
            // Load hospital
            let hospitals = try await supabaseController.fetchHospitals()
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
