//
//  Data Model.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//
import Foundation
import SwiftUI

struct SuperAdmin: Identifiable, Codable{
    var id : UUID
    var email: String
    var fullName: String
    var phoneNumber :String
    var isFirstLogin : Bool?
    var password: String
}

struct Admin: Identifiable, Codable, Hashable {
    var id: UUID
    var email: String
    var fullName: String
    var phoneNumber: String
    var hospitalId: UUID?
    var isFirstLogin: Bool?
    var initialPassword: String
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Admin, rhs: Admin) -> Bool {
        lhs.id == rhs.id
    }
}

struct Hospital: Identifiable, Codable {
    var id : UUID
    var name: String
    var address: String
    var city: String
    var state: String
    var pincode: String
    var mobileNumber: String
    var email: String
    var licenseNumber : String
    var isActive: Bool
    var assignedAdminId: UUID?
    
}

struct Department: Identifiable, Codable {
    var id : UUID
    var name: String
    var description: String?
    var hospitalId: UUID?
    var fees: Double
}

struct Doctor : Identifiable, Codable {
    var id: UUID
    var fullName: String
    var departmentId : UUID?
    var hospitalId: UUID?
    var experience : Int
    var qualifications : String
    var isActive: Bool
    var isFirstLogin: Bool?
    var initialPassword: String?
    var phoneNumber: String
    var email: String
    var gender : String
    var licenseNumber: String
    
}
struct Patient: Identifiable, Codable {
    var id: UUID
    var fullName: String
    var gender: String
    var dateOfBirth: Date
    var phoneNumber: String
    var email: String
    var detailId: UUID?
    var password: String?
}

struct PatientDetails: Identifiable, Codable {
    var id : UUID
    var bloodGroup: String?
    var allergies: String?
    var existingMedicalRecord: String?
    var currentMedication : String?
    var pastSurgeries : String?
    var emergencyContact : String?
}



struct Appointment: Codable {
    let id: UUID
    let patientId: UUID
    let doctorId: UUID
    let date: Date
    var status: AppointmentStatus
    // Add any other needed properties
}

enum AppointmentStatus: String, Codable {
    case scheduled
    case completed
    case cancelled
}
