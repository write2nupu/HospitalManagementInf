import Foundation

struct User: Codable {
    let id: UUID
    let email: String
    let full_name: String
    let phone_number: String?
    let role: String
    let is_first_login: Bool
    let is_active: Bool
    let hospital_id: UUID?
    let created_at: String
    let updated_at: String
    

} 
enum UserRole: String, Codable, CaseIterable {
    case superAdmin = "super_admin"
    case admin = "admin"
    case doctor = "doctor"
    case patient = "patient"
    
    var displayName: String {
        switch self {
        case .superAdmin: return "Super Admin"
        case .admin: return "Admin"
        case .doctor: return "Doctor"
        case .patient: return "Patient"
        }
    }
}
