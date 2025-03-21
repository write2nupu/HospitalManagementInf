import SwiftUI

struct DashBoard: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var doctor: Doctor?
    var doctorName: String = "Dr. Anubhav Dubey" // Change dynamically later

    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea() // Background color
                
                VStack(spacing: 20) {
                    // **Top Bar with Profile Button**
                    HStack {
                        Spacer() // Push button to the right
//                     /*   NavigationLink(destination: DoctorProfileView())*/ {
//                            Image(systemName: "person.crop.circle.fill")
//                                .resizable()
//                                .frame(width: 40, height: 40)
//                                .foregroundColor(AppConfig.buttonColor)
//                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // **Welcome Message**
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Welcome,")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundColor(.primary)
                        
                        Text(doctorName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .task {
                // Fetch doctor details when view appears
                // Replace with actual doctor ID
                let doctors = await supabaseController.fetchDoctors()
                // Assuming we want the first doctor for now
                doctor = doctors.first
            }
        }
    }
}

// **Preview**
struct DashBoard_Previews: PreviewProvider {
    static var previews: some View {
        DashBoard()
    }
}
