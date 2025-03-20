//
//  Data Model.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//
import Foundation
import SwiftUI

struct hospital: Identifiable {
    let id = UUID()
    var name: String
    var address: String
    var city: String
    var state: String
    var pincode: String
    var contact: String
    var email: String
    var isActive: Bool
    var password: String
    var adminName: String
    var adminEmail: String
    var adminPhone: String
}
