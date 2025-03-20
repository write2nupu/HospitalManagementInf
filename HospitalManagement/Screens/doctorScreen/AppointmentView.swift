
//
//  AppointmentView.swift
//  HospitalManagement
//
//  Created by Anubhav Dubey on 19/03/25.
//

import SwiftUI  // ✅ Use SwiftUI instead of SwiftUICore

struct AppointmentView: View {  // ✅ Conform to `View`
    var body: some View {
        VStack {
            Text("Appointments")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding()

            Spacer()

            Text("No upcoming appointments.")
                .font(.headline)
                .foregroundColor(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}

// **Preview**
#Preview {
    AppointmentView()
}

