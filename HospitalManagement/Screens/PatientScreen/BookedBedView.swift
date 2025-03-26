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
            NavigationView {
                VStack(alignment: .leading) {
                    // Booking Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 120)
                            .padding(.horizontal)
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Need a Bed?")
                                    .font(.title3)
                                    .bold()
                                Button(action: bookNow) {
                                    Text("Book Now")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: 150)
                                        .background(Color.mint)
                                        .cornerRadius(8)
                                }
                            }
                            Spacer()
                            Image(systemName: "bed.double.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.mint)
                                .padding(.trailing)
                        }
                    }
                    .padding(.bottom)
                    
                    // Booked Section
                    Text("Booked")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(bookedBeds, id: \..id) { bed in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.mint.opacity(0.1))
                                        .padding(.horizontal)
                                        .frame(height: 100)
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Bed Type: \(bed.type.rawValue)")
                                                .bold()
                                            Text("Booking Date: \(Date(), formatter: dateFormatter)")
                                            Text("Patient Name: John Doe")
                                        }
                                        Spacer()
                                        Button(action: { getDischarged(bed) }) {
                                            Text("Get Discharged")
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(Color.red)
                                                .cornerRadius(8)
                                        }
                                        .padding(.trailing)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Bed Booking")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        
        func bookNow() {
            print("Book Now Pressed")
        }
        
        func getDischarged(_ bed: BedBooking) {
            print("Discharged: \(bed.type.rawValue)")
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
