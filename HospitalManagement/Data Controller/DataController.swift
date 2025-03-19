//
//  DataController.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import Foundation
import SwiftUI
@MainActor
final class HospitalViewModel: ObservableObject {
    @Published var hospitals: [hospitals] = []
    
    func generateRandomPassword() -> String {
        let digits = "0123456789"
        return String((0..<6).map { _ in
            digits.randomElement()!
        })
    }
    
    func addHospital(_ hospital: hospitals) {
        hospitals.append(hospital)
    }
    
    func updateHospital(_ hospital: hospitals) {
        if let index = hospitals.firstIndex(where: { $0.id == hospital.id }) {
            hospitals[index] = hospital
        }
    }
}
