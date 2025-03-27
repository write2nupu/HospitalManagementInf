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
    var fullname: String
    var gender: String
    var dateofbirth: Date
    var contactno: String
    var email: String
    var detail_id: UUID?
    var password: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullname
        case gender
        case dateofbirth
        case contactno
        case email
        case detail_id
        case password
    }
    
    init(id: UUID, fullName: String, gender: String, dateOfBirth: Date, contactNo: String, email: String, detail_id: UUID? = nil, password: String? = nil) {
        self.id = id
        self.fullname = fullName
        self.gender = gender
        self.dateofbirth = dateOfBirth
        self.contactno = contactNo
        self.email = email
        self.detail_id = detail_id
        self.password = password
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fullname = try container.decode(String.self, forKey: .fullname)
        gender = try container.decode(String.self, forKey: .gender)
        
        // Handle date decoding from string
        if let dateString = try? container.decode(String.self, forKey: .dateofbirth) {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                dateofbirth = date
            } else {
                dateofbirth = Date() // Fallback to current date if parsing fails
            }
        } else {
            dateofbirth = Date() // Fallback to current date if no date string
        }
        
        contactno = try container.decode(String.self, forKey: .contactno)
        email = try container.decode(String.self, forKey: .email)
        detail_id = try container.decodeIfPresent(UUID.self, forKey: .detail_id)
        password = try container.decodeIfPresent(String.self, forKey: .password)
    }
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

enum BloodGroup: String, Codable, CaseIterable {
    case APositive = "A+"
    case ANegative = "A-"
    case BPositive = "B+"
    case BNegative = "B-"
    case ABPositive = "AB+"
    case ABNegative = "AB-"
    case OPositive = "O+"
    case ONegative = "O-"
    case Unknown = "Unknown"
    
    /// Returns the raw value of the blood group as a string
    var id: String {
        self.rawValue
    }
}

struct Appointment: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let doctorId: UUID
    let date: Date
    var status: AppointmentStatus
    let createdAt: Date
    let type : AppointmentType
}

enum AppointmentType : String, Codable {
    case Consultation
    case Emergency
}

enum AppointmentStatus: String, Codable {
    case scheduled
    case completed
    case cancelled
}

struct Invoice: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let patientid : UUID
    var amount: Int
    var paymentType: PaymentType
    var status: PaymentStatus
    let hospitalId: UUID?
}

enum PaymentStatus: String, Codable {
    case paid = "paid"
    case pending = "pending"
}

enum PaymentType: String, Codable, CaseIterable {
    case appointment
    case labTest
    case bed
}

struct Bed: Codable {
    let id: UUID
    let hospitalId: UUID?
    let price: Int
    let type: BedType
    let isAvailable : Bool?
}

enum BedType: String, Codable {
    case General
    case ICU
    case Personal
}

struct BedBooking: Codable {
    let id: UUID
    let patientId: UUID
    let hospitalId: UUID?
    let bedId: UUID
    let startDate: Date
    let endDate: Date
    let isAvailbale: Bool?
   
}
enum PaymentOption: String, Codable {
    case applePay
    case card
    case upi
}

 var paymentMethods: [(icon: String, name: String, type: PaymentOption)] = [
    ("applelogo", "Apple Pay", .applePay),
    ("creditcard.fill", "Debit/Credit Card", .card),
    ("qrcode", "UPI", .upi)
]
