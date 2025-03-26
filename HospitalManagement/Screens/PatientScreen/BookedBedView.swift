//
//  BookedBedView.swift
//  HospitalManagement
//
//  Created by Nupur on 26/03/25.
//

import SwiftUI

struct CurrentBedBookingView: View {
    @State private var bookedBeds: [BedBooking] = [
        BedBooking(id: UUID(), price: 100, type: .General),
        BedBooking(id: UUID(), price: 300, type: .ICU)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Booking Card
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
                            Button(action: bookNow) {
                                Text("Book Now")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: 150)
                                    .background(Color.mint)
                                    .cornerRadius(8)
                                    .padding(.leading, 16)
                            }
                        }
                        Spacer()
                        Image("BedBookingImage")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .padding(.trailing,40)
                        
                    }
                    .padding()
                }
                
                // Booked Section
                Text("Booked")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal,20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(bookedBeds, id: \..id) { bed in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.mint.opacity(0.1))
                                .padding(.horizontal)
                                .frame(height: 100)
                                .overlay(
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Bed Type: \(bed.type.rawValue)")
                                            .font(.headline)
                                        Text("Booking Date: \(Date(), formatter: dateFormatter)")
                                            .font(.body)
                                        Text("Patient Name: John Doe")
                                            .font(.body)
                                    }
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 10), alignment: .leading
                                )
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Bed Booking")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func bookNow() {
        print("Book Now Pressed")
    }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

// Preview
struct CurrentBedBookingView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentBedBookingView()
    }
}
