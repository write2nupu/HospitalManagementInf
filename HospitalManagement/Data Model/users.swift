import Foundation

struct users: Codable {
    let id: UUID
    let email: String
    let full_name: String
    let phone_number: String?
    var role: String
    let is_first_login: Bool
    let is_active: Bool
    let hospital_id: UUID?
    let created_at: String
    let updated_at: String
} 
