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
    var full_name: String
    var phone_number: String
    var hospital_id: UUID?
    var is_first_login: Bool?
    var initial_password: String
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Admin, rhs: Admin) -> Bool {
        lhs.id == rhs.id
    }
}

struct Hospital: Identifiable, Codable {
    var id: UUID
    var name: String
    var address: String
    var city: String
    var state: String
    var pincode: String
    var mobile_number: String
    var email: String
    var license_number: String
    var is_active: Bool
    var assigned_admin_id: UUID?
    
}

struct Department: Identifiable, Codable, Hashable {
    var id : UUID
    var name: String
    var description: String?
    var hospital_id: UUID?
    var fees: Double
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Department, rhs: Department) -> Bool {
        lhs.id == rhs.id
    }
}

struct Doctor : Identifiable, Codable {
    var id: UUID
    var full_name: String
    var department_id : UUID?
    var hospital_id: UUID?
    var experience : Int
    var qualifications : String
    var is_active: Bool
    var is_first_login: Bool?
    var initial_password: String?
    var phone_num: String
    var email_address: String
    var gender : String
    var license_num: String
    
}
struct Patient: Identifiable, Codable {
    var id: UUID
    var fullName: String
    var gender: String
    var dateOfBirth: Date
    var contactNo: String
    var email: String
    var detail_id: UUID?
    var password: String?
}

struct PatientDetails: Identifiable, Codable {
    var id : UUID
    var blood_group: String?
    var allergies: String?
    var existing_medical_record: String?
    var current_medication : String?
    var past_surgeries : String?
    var emergency_contact : String?
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

struct AuthData{
    var id: UUID?
    var role: String
}
