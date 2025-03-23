//
//  SupabaseController.swift
//  HospitalManagement
//
//  Created by Mariyo on 20/03/25.
//

import Foundation
import Supabase

class SupabaseController: ObservableObject {
    let client: SupabaseClient
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://ktbjqlbmbhberbebtbyx.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0YmpxbGJtYmhiZXJiZWJ0Ynl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMTk0MjMsImV4cCI6MjA1Nzg5NTQyM30._wdosJBARTE6y4t80snhslM3lOH2PHMmV6y-ErUdBPY"
        )
        self.encoder = JSONEncoder()
                self.encoder.keyEncodingStrategy = .convertToSnakeCase
                
                self.decoder = JSONDecoder()
                self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    func signUp(email: String, password: String, userData: [String: Any]) async throws -> User {
        print("Attempting to sign up with email:", email)
        
        // Convert userData to [String: AnyJSON]
        let signUpData: [String: AnyJSON] = userData.mapValues { value in
            if let string = value as? String {
                return .string(string)
            } else if let number = value as? Int {
                return .double(Double(number))
            } else if let number = value as? Double {
                return .double(number)
            } else if let bool = value as? Bool {
                return .bool(bool)
            } else {
                return .string(String(describing: value))
            }
        }
        
        // Create the auth user
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password,
            data: signUpData
        )
        
        print("Auth Response:", authResponse)
        
        let userId = authResponse.user.id
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        // Create user object
        let user = User(
            id: userId,
            email: email,
            full_name: userData["full_name"] as? String ?? "",
            phone_number: userData["phone_number"] as? String,
            role: userData["role"] as? String ?? "patient",
            is_first_login: userData["is_first_login"] as? Bool ?? true,
            is_active: userData["is_active"] as? Bool ?? true,
            hospital_id: nil,
            created_at: currentDate,
            updated_at: currentDate
        )
        
        // Add user to User table
        try await client
            .from("User")
            .insert(user)
            .execute()
        
        print("User added to User table successfully")
        
        // If the user is an admin, also add to Admin table
        if user.role.lowercased().contains("admin") && !user.role.lowercased().contains("super") {
            let admin = Admin(
                id: userId,
                email: user.email,
                full_name: user.full_name,
                phone_number: user.phone_number ?? "",
                hospital_id: nil,
                is_first_login: true,
                initial_password: password
            )
            
            try await client
                .from("Admin")
                .insert(admin)
                .execute()
            
            print("Admin added to Admin table successfully")
        }
        
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        print("Attempting to sign in with email:", email)
        
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        print("Auth Response:", authResponse)
        
        let userId = authResponse.user.id
        let userMetadata = authResponse.user.userMetadata
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        print("Raw userMetadata:", userMetadata)
        
        // Extract values from userMetadata
        let fullName = userMetadata["full_name"] as? String ?? ""
        let phoneNumber = userMetadata["phone_number"] as? String ?? ""
        
        // Extract and normalize role
        var role = "patient"  // default role
        if let metadataRole = userMetadata["role"] {
            // Handle both String and non-String cases
            if let roleStr = metadataRole as? String {
                role = roleStr
            } else {
                // If it's not a String, convert it to string
                role = String(describing: metadataRole)
            }
        } else if let authRole = authResponse.user.role {
            role = authRole
        }
        
        // Normalize role to lowercase for comparison
        role = role.lowercased()
        print("Role after normalization:", role)
        
        // Create a User object directly from the auth response
        let user = User(
            id: userId,
            email: authResponse.user.email ?? email,
            full_name: fullName,
            phone_number: phoneNumber,
            role: role,
            is_first_login: true,
            is_active: true,
            hospital_id: nil,
            created_at: currentDate,
            updated_at: currentDate
        )
        
        print("Created user object with role:", user.role)
        
        // For super_admin role, we don't need to store in any table
        if role.contains("super") && role.contains("admin") {
            print("Detected super admin role, returning user directly")
            return user
        }
        
        // For other roles, try to find or create in their respective tables
        switch role {
        case "admin":
            // Try to fetch existing admin
            do {
                let admins: [Admin] = try await client.database
                    .from("Admin")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .execute()
                    .value
                
                if let _ = admins.first {
                    return user
                }
                
                // Create new admin if not found
                let admin = Admin(
                    id: userId,
                    email: user.email,
                    full_name: user.full_name,
                    phone_number: user.phone_number ?? "",
                    hospital_id: nil,
                    is_first_login: true,
                    initial_password: String((0..<6).map { _ in "0123456789".randomElement()! })
                )
                
                try await client.database
                    .from("Admin")
                    .insert(admin)
                    .execute()
            } catch {
                print("Error handling admin user:", error)
            }
            
        case "doctor":
            // Similar logic for doctors
            break
            
        case "patient":
            // Similar logic for patients
            break
            
        default:
            print("Unhandled role type:", role)
            break
        }
        
        return user
    }
    
    // MARK: - Fetch Patients
    func fetchPatients() async -> [Patient] {
        do {
            let patients: [Patient] = try await client
            
                .from("Patients")
                .select()
                .execute()
                .value
            return patients
        } catch {
            print("Error fetching patients: \(error)")
            return []
        }
    }
    
    // MARK: - Insert Patient
    func addPatient(patient: Patient) async {
        do {
            try await client
            
                .from("Patients")
                .insert(patient)
                .execute()
            print("Patient added successfully!")
        } catch {
            print("Error adding patient: \(error)")
        }
    }
    
    // MARK: - Fetch Doctors
    func fetchDoctors() async -> [Doctor] {
        do {
            let doctors: [Doctor] = try await client
            
                .from("Doctor")
                .select()
                .execute()
                .value
            return doctors
        } catch {
            print("Error fetching doctors: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Hospitals
    func fetchHospitals() async -> [Hospital] {
        do {
            let hospitals: [Hospital] = try await client
                .from("Hospitals")  // Capital H to match schema
                .select()
                .order("name")
                .execute()
                .value
            return hospitals
        } catch {
            print("Error fetching hospitals: \(error)")
            return []
        }
    }
    
    // MARK: - Update Patient Details
    func updatePatientDetails(detailID: UUID, updatedDetails: PatientDetails) async {
        do {
            try await client
            
                .from("PatientDetails")
                .update(updatedDetails)
                .eq("detail_id", value: detailID)
                .execute()
            print("Patient details updated successfully!")
        } catch {
            print("Error updating patient details: \(error)")
        }
    }
    
    // MARK: - Delete Doctor
    func deleteDoctor(doctorID: UUID) async {
        do {
            try await client
            
                .from("Doctor")
                .delete()
                .eq("id", value: doctorID)
                .execute()
            print("Doctor deleted successfully!")
        } catch {
            print("Error deleting doctor: \(error)")
        }
    }
    
    // MARK: - Fetch Admin by UUID
    func fetchAdminByUUID(adminId: UUID) async -> Admin? {
        do {
            let admins: [Admin] = try await client
                .from("Admin")
                .select()
                .eq("id", value: adminId)
                .execute()
                .value
            return admins.first
        } catch {
            print("Error fetching admin: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Department Details
    func fetchDepartmentDetails(departmentId: UUID) async -> Department? {
        do {
            let departments: [Department] = try await client
                .from("Department")
                .select()
                .eq("id", value: departmentId)
                .execute()
                .value
            return departments.first
        } catch {
            print("Error fetching department: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Doctors with Department Details
    func fetchDoctorsWithDepartment() async -> [Doctor] {
        do {
            let doctors: [Doctor] = try await client
                .from("Doctor")
                .select("""
                    id,
                    full_Name,
                    departmentId,
                    hospitalId,
                    experience,
                    qualifications,
                    isActive,
                    isFirstLogin,
                    initialPassword,
                    phoneNumber,
                    email,
                    gender,
                    licenseNumber,
                    Departments (
                        name,
                        fees
                    )
                """)
                .execute()
                .value
            return doctors
        } catch {
            print("Error fetching doctors with departments: \(error)")
            return []
        }
    }
    
    // MARK: - Add Hospital
    func addHospital(_ hospital: Hospital) async throws {
        do {
            try await client
                .from("Hospitals")  // Capital H to match schema
                .insert(hospital)
                .single()  // expect a single row
                .execute()
            print("Hospital added successfully!")
        } catch {
            print("Error adding hospital: \(error)")
            throw error  // propagate the error
        }
    }
    
    // MARK: - Fetch Doctor by UUID
    func fetchDoctorByUUID(doctorId: UUID) async -> Doctor? {
        do {
            let doctors: [Doctor] = try await client
                .from("Doctors")
                .select("""
                    id,
                    fullName,
                    departmentId,
                    hospitalId,
                    experience,
                    qualifications,
                    isActive,
                    isFirstLogin,
                    initialPassword,
                    phoneNumber,
                    email,
                    gender,
                    licenseNumber,
                    Departments (
                        name,
                        fees
                    )
                """)
                .eq("id", value: doctorId)
                .execute()
                .value
            return doctors.first
        } catch {
            print("Error fetching doctor: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Doctor
    func updateDoctor(_ doctor: Doctor) async {
        do {
            try await client
                .from("Doctors")
                .update(doctor)
                .eq("id", value: doctor.id)
                .execute()
            print("Doctor updated successfully!")
        } catch {
            print("Error updating doctor: \(error)")
        }
    }
    
    // MARK: - Fetch Hospital Affiliations
    func fetchHospitalAffiliations(doctorId: UUID) async -> [String] {
        do {
            let hospitals: [Hospital] = try await client
                .from("Hospitals")
                .select()
                .eq("id", value: doctorId)
                .execute()
                .value
            return hospitals.map { $0.name }
        } catch {
            print("Error fetching hospital affiliations: \(error)")
            return []
        }
    }

    // MARK: - Fetch Hospital Departments
    func fetchHospitalDepartments(hospitalId: UUID) async -> [Department] {
        do {
            let departments: [Department] = try await client
                .from("Departments")
                .select()
                .eq("hospitalId", value: hospitalId)
                .execute()
                .value
            return departments
        } catch {
            print("Error fetching hospital departments: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Patient Details
    func fetchPatientDetails(patientId: UUID) async -> Patient? {
        do {
            let patients: [Patient] = try await client
                .from("Patients")
                .select()
                .eq("id", value: patientId)
                .execute()
                .value
            return patients.first
        } catch {
            print("Error fetching patient: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Patient Details
    func updatePatient(_ patient: Patient) async {
        do {
            try await client
                .from("Patients")
                .update(patient)
                .eq("id", value: patient.id)
                .execute()
            print("Patient updated successfully!")
        } catch {
            print("Error updating patient: \(error)")
        }
    }
    
    // MARK: - Get Doctors by Hospital
    func getDoctorsByHospital(hospitalId: UUID) async -> [Doctor] {
        do {
            let doctors: [Doctor] = try await client
                .from("Doctors")
                .select("""
                    id,
                    full_name,
                    departmentId,
                    hospitalId,
                    experience,
                    qualifications,
                    isActive,
                    isFirstLogin,
                    initialPassword,
                    phoneNumber,
                    email,
                    gender,
                    licenseNumber,
                    Departments (
                        name,
                        fees
                    )
                """)
                .eq("hospitalId", value: hospitalId)
                .execute()
                .value
            return doctors
        } catch {
            print("Error fetching doctors by hospital: \(error)")
            return []
        }
    }
    
    // MARK: - Create Default Super Admin
    func createDefaultSuperAdmin() async throws {
        let defaultEmail = "tarunmariya320@gmail.com"
        let defaultPassword = "Admin@123"
        let defaultFullName = "Super Admin"
        let defaultPhone = "1234567890"
        
        // Check if super admin already exists
        let existingUsers: [User] = try await client
            .from("User")
            .select()
            .eq("role", value: "super_admin")
            .execute()
            .value
        
        if existingUsers.isEmpty {
            print("No existing super admin found, creating one...")
            // Create auth user with super admin role
            let userData: [String: Any] = [
                "full_name": defaultFullName,
                "phone_number": defaultPhone,
                "role": "super_admin",
                "is_first_login": true,
                "is_active": true
            ]
            
            // Sign up the super admin
            _ = try await signUp(email: defaultEmail, password: defaultPassword, userData: userData)
            print("Default super admin created successfully")
        } else {
            print("Super admin already exists")
        }
    }
}
