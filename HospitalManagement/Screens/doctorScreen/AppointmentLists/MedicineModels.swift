//
//  MedicineModels.swift
//  HospitalManagement
//
//  Created by Jashan on 27/03/25.
//

import Foundation




struct MedicineResponse: Codable, Identifiable {
    let id: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "Name"
    }
}

struct PrescribedMedicine: Identifiable {
    let id = UUID()
    let medicine: MedicineResponse
    var dosage: String
    var duration: String
    var timing: String
}


