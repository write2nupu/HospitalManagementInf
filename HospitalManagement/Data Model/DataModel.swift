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

struct Doctor: Identifiable, Codable {
    var id: UUID
    var full_name: String
    var department_id: UUID?
    var hospital_id: UUID?
    var experience: Int
    var qualifications: String
    var is_active: Bool
    var is_first_login: Bool?
    var initial_password: String?
    var phone_num: String
    var email_address: String
    var gender: String
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
    let type: AppointmentType
    let prescriptionId: UUID?
    
    // Update initializer
    init(id: UUID, patientId: UUID, doctorId: UUID, date: Date, status: AppointmentStatus, createdAt: Date, type: AppointmentType, prescriptionId: UUID? = nil) {
        self.id = id
        self.patientId = patientId
        self.doctorId = doctorId
        self.date = date
        self.status = status
        self.createdAt = createdAt
        self.type = type
        self.prescriptionId = prescriptionId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case patientId
        case doctorId
        case date
        case status
        case createdAt
        case type
        case prescriptionId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        doctorId = try container.decode(UUID.self, forKey: .doctorId)
        status = try container.decode(AppointmentStatus.self, forKey: .status)
        type = try container.decode(AppointmentType.self, forKey: .type)
        
        // Handle optional prescriptionId
        if let prescriptionIdString = try container.decodeIfPresent(String.self, forKey: .prescriptionId) {
            prescriptionId = UUID(uuidString: prescriptionIdString)
        } else {
            prescriptionId = nil
        }
        
        // Handle date decoding with multiple formats
        let dateString = try container.decode(String.self, forKey: .date)
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm"
        ]
        
        func parseDate(_ dateString: String, formats: [String]) -> Date? {
            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            return nil
        }
        
        if let parsedDate = parseDate(dateString, formats: dateFormats) {
            date = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        
        if let parsedCreatedAt = parseDate(createdAtString, formats: dateFormats) {
            createdAt = parsedCreatedAt
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Invalid date format: \(createdAtString)"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(patientId, forKey: .patientId)
        try container.encode(doctorId, forKey: .doctorId)
        try container.encode(status, forKey: .status)
        try container.encode(type, forKey: .type)
        
        // Encode optional prescriptionId
        if let prescriptionId = prescriptionId {
            try container.encode(prescriptionId.uuidString, forKey: .prescriptionId)
        } else {
            try container.encodeNil(forKey: .prescriptionId)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        
        try container.encode(dateFormatter.string(from: date), forKey: .date)
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
    }
}

enum AppointmentType : String, Codable {
    case Consultation = "Consultation"
    case Emergency = "Emergency"
}

enum AppointmentStatus: String, Codable {
    case scheduled = "Scheduled"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct Invoice: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let patientid : UUID
    var amount: Int
    var paymentType: PaymentType
    var status: PaymentStatus
    var hospitalId: UUID?
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

struct Bed: Identifiable, Codable {
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
    let isAvailable: Bool?
   
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

struct PrescriptionData: Codable {
    let id: UUID
    let patientId: UUID
    let doctorId: UUID
    let diagnosis: String
    let labTests: [String]?
    let additionalNotes: String?
    let medicineName: String?
    let medicineDosage: DosageOption?
    let medicineDuration: DurationOption?
    
    enum CodingKeys: String, CodingKey {
        case id
        case patientId
        case doctorId
        case diagnosis
        case labTests
        case additionalNotes
        case medicineName
        case medicineDosage
        case medicineDuration
    }
}
enum DosageOption: String, CaseIterable, Codable {
    case oneDaily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case thriceDaily = "Thrice Daily"
    case beforeMeal = "Before Meals"
    case afterMeal = "After Meals"
    case asNeeded = "As Needed"
}

enum DurationOption: String, CaseIterable, Codable {
    case threeDays = "3 Days"
    case fiveDays = "5 Days"
    case sevenDays = "7 Days"
    case tenDays = "10 Days"
    case fifteenDays = "15 Days"
    case thirtyDays = "30 Days"
    case continuous = "Continuous"
}

// MARK: - Leave Request Model
struct Leave: Identifiable, Codable {
    let id: UUID
    let doctorId: UUID
    let hospitalId: UUID
    let type: LeaveType
    let reason: String
    let startDate: Date
    let endDate: Date
    var status: LeaveStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case doctorId
        case hospitalId
        case type
        case reason
        case startDate
        case endDate
        case status
    }
    
    init(from decoder: Decoder) throws {
        print("Starting to decode Leave object")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(UUID.self, forKey: .id)
            print("Successfully decoded id: \(id)")
        } catch {
            print("Error decoding id: \(error)")
            throw error
        }
        
        do {
            doctorId = try container.decode(UUID.self, forKey: .doctorId)
            print("Successfully decoded doctorId: \(doctorId)")
        } catch {
            print("Error decoding doctorId: \(error)")
            throw error
        }
        
        do {
            hospitalId = try container.decode(UUID.self, forKey: .hospitalId)
            print("Successfully decoded hospitalId: \(hospitalId)")
        } catch {
            print("Error decoding hospitalId: \(error)")
            throw error
        }
        
        do {
            type = try container.decode(LeaveType.self, forKey: .type)
            print("Successfully decoded type: \(type)")
        } catch {
            print("Error decoding type: \(error)")
            throw error
        }
        
        do {
            reason = try container.decode(String.self, forKey: .reason)
            print("Successfully decoded reason: \(reason)")
        } catch {
            print("Error decoding reason: \(error)")
            throw error
        }
        
        do {
            status = try container.decode(LeaveStatus.self, forKey: .status)
            print("Successfully decoded status: \(status)")
        } catch {
            print("Error decoding status: \(error)")
            throw error
        }
        
        // Handle date decoding with multiple formats
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        ]
        
        func parseDate(_ dateString: String, formats: [String]) -> Date? {
            print("Attempting to parse date string: \(dateString)")
            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    print("Successfully parsed date using format: \(format)")
                    return date
                }
            }
            print("Failed to parse date string with any format")
            return nil
        }
        
        do {
            let startDateString = try container.decode(String.self, forKey: .startDate)
            print("Successfully decoded startDate string: \(startDateString)")
            
            if let parsedStartDate = parseDate(startDateString, formats: dateFormats) {
                startDate = parsedStartDate
                print("Successfully parsed startDate: \(startDate)")
            } else {
                print("Failed to parse startDate string: \(startDateString)")
                throw DecodingError.dataCorruptedError(
                    forKey: .startDate,
                    in: container,
                    debugDescription: "Invalid start date format: \(startDateString)"
                )
            }
        } catch {
            print("Error decoding startDate: \(error)")
            throw error
        }
        
        do {
            let endDateString = try container.decode(String.self, forKey: .endDate)
            print("Successfully decoded endDate string: \(endDateString)")
            
            if let parsedEndDate = parseDate(endDateString, formats: dateFormats) {
                endDate = parsedEndDate
                print("Successfully parsed endDate: \(endDate)")
            } else {
                print("Failed to parse endDate string: \(endDateString)")
                throw DecodingError.dataCorruptedError(
                    forKey: .endDate,
                    in: container,
                    debugDescription: "Invalid end date format: \(endDateString)"
                )
            }
        } catch {
            print("Error decoding endDate: \(error)")
            throw error
        }
        
        print("Successfully decoded all fields of Leave object")
    }
}

enum LeaveType: String, Codable {
    case sick = "sick"
    case vacation = "vacation"
    case personal = "personal"
    case casual = "Casual Leave"
    case other = "other"
}

enum LeaveStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
}
