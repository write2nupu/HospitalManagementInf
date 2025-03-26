import SwiftUI

struct BedBookingView: View {
    @State private var selectedBedType: BedType = .General
    @State private var price: Int = 100
    @State private var availableBeds: [BedType: Int] = [
        .General: 5,
        .ICU: 2,
        .Personal: 1
    ]
    @State private var showActionSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Bed Type")
                            .font(.headline)
                        Picker("Bed Type", selection: $selectedBedType) {
                            Text("General").tag(BedType.General)
                            Text("ICU").tag(BedType.ICU)
                            Text("Personal").tag(BedType.Personal)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedBedType) { newValue in
                            switch newValue {
                            case .General: price = 1000
                            case .ICU: price = 3000
                            case .Personal: price = 4000
                            }
                        }
                        
                        Text("Price")
                            .font(.headline)
                        Text("$\(price)")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.mint.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Available Beds")
                            .font(.headline)
                        Text("\(availableBeds[selectedBedType] ?? 0) beds available")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.mint.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                
                Button(action: { showActionSheet = true }) {
                    Text("Proceed")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mint)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom)
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(
                        title: Text("Confirm Action"),
                        message: Text("Do you want to book the bed immediately or request it in advance?"),
                        buttons: [
                            .default(Text("Book Bed")) { bookBed() },
                            .default(Text("Request Bed")) { requestBed() },
                            .cancel()
                        ]
                    )
                }
            }
            .navigationTitle("Book Bed")
        }
    }
    
    func bookBed() {
        print("Bed Booked: \(selectedBedType.rawValue) with price: $\(price)")
    }
    
    func requestBed() {
        print("Bed Requested: \(selectedBedType.rawValue) with price: $\(price)")
    }
}

// Sample preview
struct BedBookingView_Previews: PreviewProvider {
    static var previews: some View {
        BedBookingView()
    }
}
