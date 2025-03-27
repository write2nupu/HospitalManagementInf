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
            supabaseURL: URL(string: "https://lsjxoslxrmubrcpzgnrk.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxzanhvc2x4cm11YnJjcHpnbnJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3MDQwOTgsImV4cCI6MjA1ODI4MDA5OH0.wxc_rk_L_9R08wyjuoTX8KyYUJ71LDxdZ9n7RFNkzwE"
        )
        self.encoder = JSONEncoder()
                self.encoder.keyEncodingStrategy = .convertToSnakeCase
                
                self.decoder = JSONDecoder()
                self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    func signUp(email: String, password: String, userData: [String: Any]) async throws -> users {
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
        let user = users(
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
            .from("users")
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
    
    func signIn(email: String, password: String) async throws -> users {
        print("Attempting to sign in with email:", email)
        
        // First check if user exists in Admin table
        let admins: [Admin] = try await client.database
            .from("Admin")
            .select()
            .eq("email", value: email)
            .execute()
            .value
        
        print("Found \(admins.count) admin(s) with email: \(email)")
        
        if let admin = admins.first {
            print("Found admin in Admin table:", admin.email)
            
            // Then try to authenticate
            do {
                let authResponse = try await client.auth.signIn(
                    email: email,
                    password: password
                )
                print("Authentication successful for admin")
                
                // Check if user exists in Users table
                let existingUsers: [users] = try await client.database
                    .from("users")
                    .select()
                    .eq("email", value: email)
                    .execute()
                    .value
                
                print("Found \(existingUsers.count) user(s) with email: \(email)")
                
                if let existingUser = existingUsers.first {
                    print("Found existing user with role:", existingUser.role)
                    // Update role to ensure it's admin
                    if existingUser.role != "admin" {
                        var updatedUser = existingUser
                        updatedUser.role = "admin"
                        try await client.database
                            .from("users")
                            .update(updatedUser)
                            .eq("id", value: existingUser.id)
                            .execute()
                        print("Updated user role to admin")
                        return updatedUser
                    }
                    return existingUser
                }
                
                // Create new user record for admin
                let adminUser = users(
                    id: authResponse.user.id,
                    email: admin.email,
                    full_name: admin.full_name,
                    phone_number: admin.phone_number,
                    role: "admin",
                    is_first_login: admin.is_first_login ?? true,
                    is_active: true,
                    hospital_id: admin.hospital_id,
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await client.database
                    .from("users")
                    .insert(adminUser)
                    .execute()
                
                print("Created new user record with admin role")
                return adminUser
            } catch {
                print("Authentication error:", error.localizedDescription)
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials. Please check your email and password."])
            }
        }
        
        print("No admin found with email: \(email)")
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Access denied. You must be an Admin to login."])
    }
    
    // MARK: - Fetch Patients
    func fetchPatients() async -> [Patient] {
        do {
            let patients: [Patient] = try await client
            
                .from("Patients")
                .select()
//                .eq("id", value: patientId)
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
                .from("Hospital")  // Capital H to match schema
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
                .from("Hospital")  // Capital H to match schema
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
                .from("Doctor")
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
                .from("Doctor")
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
                .from("Hospital")
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

//    // MARK: - Fetch Hospital Departments
//    func fetchHospitalDepartments(hospitalId: UUID) async -> [Department] {
//        do {
//            let departments: [Department] = try await client
//                .from("Department")
//                .select()
//                .eq("hospitalId", value: hospitalId)
//                .execute()
//                .value
//            return departments
//        } catch {
//            print("Error fetching hospital departments: \(error)")
//            return []
//        }
//    }
//    
    // MARK: - Fetch Patient Details
    func fetchPatientDetails(patientId: UUID) async -> Patient? {
        do {
            let patients: [Patient] = try await client
                .from("Patient")
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
                .from("Patient")
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
                .from("Doctor")
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
        let existingUsers: [users] = try await client
            .from("users")
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

// MARK: - Fetch Departments by Hospital
func fetchHospitalDepartments(hospitalId: UUID) async throws -> [Department] {
    let departments: [Department] = try await client
        .from("Department")
        .select()
        .eq("hospital_id", value: hospitalId.uuidString)
        .execute()
        .value
    return departments
}

// MARK: - Fetch Doctors by Department
func getDoctorsByDepartment(departmentId: UUID) async throws -> [Doctor] {
    let doctors: [Doctor] = try await client
        .from("Doctor")
        .select()
        .eq("department_id", value: departmentId.uuidString)
        .execute()
        .value
    return doctors
}

// MARK: - Patient Authentication
func signUpPatient(email: String, password: String, userData: Patient) async throws -> Patient {
    print("Attempting to sign up patient with email:", email)
    
    let lowercaseEmail = email.lowercased()
    
    // First create the auth user
    let authResponse = try await client.auth.signUp(
        email: lowercaseEmail,
        password: password
    )
    
    print("Auth Response:", authResponse)
    
    let userId = authResponse.user.id
    let currentDate = ISO8601DateFormatter().string(from: Date())
    
    // Create user record in users table
    let user = users(
        id: userId,
        email: lowercaseEmail,
        full_name: userData.fullname,
        phone_number: userData.contactno,
        role: "patient",
        is_first_login: true,
        is_active: true,
        hospital_id: nil,
        created_at: currentDate,
        updated_at: currentDate
    )
    
    try await client
        .from("users")
        .insert(user)
        .execute()
    
    print("User added to users table successfully")
    
    // Create patient record with proper formatting
    let dateFormatter = ISO8601DateFormatter()
    let patientData: [String: AnyJSON] = [
        "id": .string(userId.uuidString),
        "fullname": .string(userData.fullname),
        "gender": .string(userData.gender),
        "dateofbirth": .string(dateFormatter.string(from: userData.dateofbirth)),
        "contactno": .string(userData.contactno),
        "email": .string(lowercaseEmail),
        "detail_id": .null
    ]
    
    print("Attempting to insert patient data:", patientData)
    
    let insertedPatients: [Patient] = try await client
        .from("Patient")
        .insert(patientData)
        .select()
        .execute()
        .value
    
    guard let insertedPatient = insertedPatients.first else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create patient record"])
    }
    
    print("Patient added to Patient table successfully")
    return insertedPatient
}

func signInPatient(email: String, password: String) async throws -> Patient {
    print("Attempting to sign in patient with email:", email)
    
    let lowercaseEmail = email.lowercased()
    
    // First authenticate the user
    let authResponse = try await client.auth.signIn(
        email: lowercaseEmail,
        password: password
    )
    
    print("Authentication successful")
    print("User ID from auth:", authResponse.user.id)
    
    // Create a decoder that matches our date format
    let decoder = JSONDecoder()
    let dateFormatter = ISO8601DateFormatter()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot decode date string \(dateString)"
        )
    }
    
    // Fetch patient details using the user ID
    let patients: [Patient] = try await client
        .from("Patient")
        .select()
        .eq("id", value: authResponse.user.id.uuidString)
        .execute()
        .value
    
    guard let patient = patients.first else {
        print("No patient found with ID:", authResponse.user.id.uuidString)
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Patient account not found. Please contact support."])
    }
    
    print("Patient found:", patient.fullname)
    return patient
}

// MARK: - Doctor Profile and Appointments
func fetchDoctorProfile(doctorId: UUID) async throws -> Doctor {
    let doctors: [Doctor] = try await client
        .from("Doctor")
        .select("""
            id,
            full_name,
            department_id,
            hospital_id,
            experience,
            qualifications,
            is_active,
            is_first_login,
            phone_num,
            email_address,
            gender,
            license_num,
            Department (
                name,
                fees
            ),
            Hospital (
                name
            )
        """)
        .eq("id", value: doctorId.uuidString)
        .execute()
        .value
    
    guard let doctor = doctors.first else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Doctor not found"])
    }
    
    return doctor
}

func fetchDoctorAppointments(doctorId: UUID) async throws -> [Appointment] {
    let appointments: [Appointment] = try await client
        .from("Appointment")
        .select("""
            id,
            patientId,
            doctorId,
            date,
            status,
            createdAt,
            type,
            prescriptionId,
            Patient!inner (
                id,
                fullname,
                gender,
                dateofbirth,
                contactno,
                email
            )
        """)
        .eq("doctorId", value: doctorId.uuidString)
        .order("date")
        .execute()
        .value
    
    return appointments
}

func fetchDoctorStats(doctorId: UUID) async throws -> (completedAppointments: Int, activePatients: Int) {
    // Get completed appointments count
    let completedAppointments: [Appointment] = try await client
        .from("Appointment")
        .select()
        .eq("doctorId", value: doctorId.uuidString)
        .eq("status", value: AppointmentStatus.completed.rawValue)
        .execute()
        .value
    
    // Get unique patients count from active appointments
    let activeAppointments: [Appointment] = try await client
        .from("Appointment")
        .select()
        .eq("doctorId", value: doctorId.uuidString)
        .eq("status", value: AppointmentStatus.scheduled.rawValue)
        .execute()
        .value
    
    let uniquePatients = Set(activeAppointments.map { $0.patientId })
    
    return (completedAppointments.count, uniquePatients.count)
}

// MARK: - Department Operations
func fetchDepartmentDetails(departmentId: UUID) async throws -> Department {
    let departments: [Department] = try await client
        .from("Department")
        .select()
        .eq("id", value: departmentId.uuidString)
        .execute()
        .value
    
    guard let department = departments.first else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Department not found"])
    }
    
    return department
}

// MARK: - Prescription Operations
func fetchPrescription(prescriptionId: UUID) async throws -> PrescriptionData {
    let prescriptions: [PrescriptionData] = try await client
        .from("Prescription")
        .select("""
            id,
            patientId,
            doctorId,
            diagnosis,
            labTests,
            additionalNotes
        """)
        .eq("id", value: prescriptionId.uuidString)
        .execute()
        .value
    
    guard let prescription = prescriptions.first else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Prescription not found"])
    }
    
    return prescription
}

func savePrescription(_ prescription: PrescriptionData) async throws {
    try await client
        .from("Prescription")
        .upsert(prescription)
        .execute()
}

// MARK: - Patient Operations
func fetchPatientById(patientId: UUID) async throws -> Patient {
    let patients: [Patient] = try await client
        .from("Patient")
        .select()
        .eq("id", value: patientId.uuidString)
        .execute()
        .value
    
    guard let patient = patients.first else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Patient not found"])
    }
    
    return patient
}

// MARK: - Hospital Operations
func fetchHospitalById(hospitalId: UUID) async throws -> Hospital {
    let hospitals: [Hospital] = try await client
        .from("Hospital")
        .select()
        .eq("id", value: hospitalId.uuidString)
        .execute()
        .value
    
    guard let hospital = hospitals.first else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hospital not found"])
    }
    
    return hospital
}
}
