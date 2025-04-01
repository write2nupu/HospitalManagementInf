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
        let admins: [Admin] = try await client
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
                let existingUsers: [users] = try await client
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
                        try await client
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
                
                try await client
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
    
    func fetchPatientDetails() async -> [PatientDetails] {
        do {
            let patientDetails: [PatientDetails] = try await client
                .from("Patientdetails")
                .select()
                .execute()
                .value
            return patientDetails
            
        } catch {
            print("Error fetching patient Details: \(error)")
            return[]
        }
    }
    
    func addPatientDetails(patientDetails: PatientDetails) async {
        do {
            try await client
            
                .from("Patientdetails")
                .insert(patientDetails)
                .execute()
            print("Patient Details added successfully!")
        } catch {
            print("Error adding patient Details: \(error)")
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

    
    func fetchHospitalAndAdmin() async throws -> (Hospital, String)? {
        print("Fetching hospital and admin details")
        
        // First get all hospitals with their assigned admins
        let hospitals: [Hospital] = try await client
            .from("Hospital")
            .select("*")
            .execute()
            .value
        guard let hospital = hospitals.first else {
            print("No hospital found")
            return nil
        }
    
    // Get admin details using assigned_admin_id from hospital
        if let assignedAdminId = hospital.assigned_admin_id {
            let admins: [Admin] = try await client
                .from("Admin")
                .select("*")
                .eq("id", value: assignedAdminId.uuidString)
                .execute()
                .value
            
            if let admin = admins.first {
                print("Found hospital: \(hospital.name) with admin: \(admin.full_name)")
                return (hospital, admin.full_name)
            }
        }
    
        return nil
    }

        

// Add function to sign in admin and store their ID
func signInAdmin(email: String, password: String) async throws -> Admin {
    print("Attempting to sign in admin with email:", email)
    
    let authResponse = try await client.auth.signIn(
        email: email,
        password: password
    )
    
    let adminId = authResponse.user.id.uuidString
    print("Storing admin ID in UserDefaults:", adminId)
    UserDefaults.standard.set(adminId, forKey: "currentAdminId")
    // Verify it was stored
    print("Verifying stored admin ID:", UserDefaults.standard.string(forKey: "currentAdminId") ?? "Not found")
    
    // Fetch admin details
    let admins: [Admin] = try await client
        .from("Admin")
        .select()
        .eq("id", value: authResponse.user.id.uuidString)
        .execute()
        .value
    
    guard let admin = admins.first else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Admin account not found."])
    }
    
    return admin
}

func fetchAdminProfile() async throws -> (Admin, Hospital)? {
    print("Fetching admin profile details")
    
    // First get the hospital with assigned admin
    let hospitals: [Hospital] = try await client
        .from("Hospital")
        .select("*")
        .execute()
        .value
    
    guard let hospital = hospitals.first else {
        print("No hospital found")
        return nil
    }
    
    // Get admin details using assigned_admin_id from hospital
    if let assignedAdminId = hospital.assigned_admin_id {
        let admins: [Admin] = try await client
            .from("Admin")
            .select("*")
            .eq("id", value: assignedAdminId.uuidString)
            .execute()
            .value
        
        if let admin = admins.first {
            print("Found admin profile with hospital details")
            return (admin, hospital)
        }
    }
    
    return nil
}

func updateAdmin(_ admin: Admin) async throws {
    try await client
        .from("Admin")
        .update(admin)
        .eq("id", value: admin.id)
        .execute()
    print("Admin updated successfully!")
}

func fetchSuperAdminProfile() async throws -> users? {
    print("Attempting to fetch super admin profile")
    let superAdmins: [users] = try await client
        .from("users")
        .select("*")  // Make sure we're selecting all fields
        .eq("role", value: "super_admin")
        .execute()
        .value
    
    if let superAdmin = superAdmins.first {
        print("Found super admin: \(superAdmin.full_name)")
        return superAdmin
    }
    print("No super admin found")
    return nil
}

func updateHospital(_ hospital: Hospital) async throws {
    try await client
        .from("Hospital")
        .update(hospital)
        .eq("id", value: hospital.id)
        .execute()
    print("Hospital updated successfully!")
}

// MARK: - Bed Management Functions
func fetchAllBeds(hospitalId: UUID? = nil) async throws -> [Bed] {
    var query = client
        .from("Bed")
        .select("""
            id,
            hospitalId,
            price,
            type,
            isAvailable
        """)
    
    if let hospitalId = hospitalId {
        query = query.eq("hospitalId", value: hospitalId.uuidString)
    }
    
    do {
        let beds: [Bed] = try await query
            .execute()
            .value
        
        return beds
    } catch let error as PostgrestError {
        print("Postgrest error fetching beds: \(error)")
        throw error
    } catch let error as DecodingError {
        // Handle specific decoding errors
        print("Decoding error fetching beds: \(error)")
        
        // Attempt to recover with a manual decode
        let response = try await query.execute()
        // Check if response.data exists and isn't nil
        if let jsonObject = response.data as? [[String: Any]], !jsonObject.isEmpty {
            do {
                // Try to manually decode the response
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
                let decoder = JSONDecoder()
                
                // Create a custom decoder to handle missing values
                let beds = try decoder.decode([SafeBed].self, from: jsonData).map { safeBed -> Bed in
                    return Bed(
                        id: safeBed.id,
                        hospitalId: safeBed.hospitalId,
                        price: safeBed.price ?? 0,  // Default to 0 if price is missing
                        type: safeBed.type ?? .General,  // Default to General if type is missing
                        isAvailable: safeBed.isAvailable ?? true  // Default to true if isAvailable is missing
                    )
                }
                return beds
            } catch {
                print("Failed to manually decode beds: \(error)")
                return []  // Return empty array instead of throwing
            }
        }
        return []  // Return empty array if data is nil
    } catch {
        print("Unknown error fetching beds: \(error)")
        throw error
    }
}

// Safe decoding structure for Bed
private struct SafeBed: Codable {
    let id: UUID
    let hospitalId: UUID?
    let price: Int?
    let type: BedType?
    let isAvailable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, hospitalId, price, type, isAvailable
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required field - will throw if missing
        id = try container.decode(UUID.self, forKey: .id)
        
        // Optional fields - use nil if missing or can't be decoded
        hospitalId = try container.decodeIfPresent(UUID.self, forKey: .hospitalId)
        
        // Handle price which might be a Double in the database but Int in our model
        if let priceDouble = try? container.decodeIfPresent(Double.self, forKey: .price) {
            price = Int(priceDouble)
        } else {
            price = try? container.decodeIfPresent(Int.self, forKey: .price)
        }
        
        // Handle bed type which might be a string
        if let typeString = try? container.decodeIfPresent(String.self, forKey: .type),
           let bedType = BedType(rawValue: typeString) {
            type = bedType
        } else {
            type = try? container.decodeIfPresent(BedType.self, forKey: .type)
        }
        
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable)
    }
}

func addBeds(beds: [Bed], hospitalId: UUID) async throws {
    // Convert beds to match schema
    let bedData = beds.map { bed -> [String: AnyJSON] in
        return [
            "id": .string(bed.id.uuidString),
            "hospitalId": .string(hospitalId.uuidString),  // Always use the provided hospitalId
            "price": .double(Double(bed.price)),
            "type": .string(bed.type.rawValue),
            "isAvailable": .bool(true)  // New beds should be available by default
        ]
    }
    
    try await client
        .from("Bed")
        .insert(bedData)
        .execute()
}

func updateBedAvailability(bedId: UUID, isAvailable: Bool) async throws {
    try await client
        .from("Bed")
        .update(["isAvailable": isAvailable])
        .eq("id", value: bedId.uuidString)
        .execute()
}

func getRecentBedBookings(hospitalId: UUID? = nil, limit: Int = 10) async throws -> [BedBookingWithDetails] {
    do {
        var query = client
            .from("BedBooking")
            .select("""
                id,
                patientId,
                bedId,
                startDate,
                endDate,
                isAvailable,
                Patient (
                    id,
                    fullname
                ),
                Bed (
                    id,
                    type,
                    price,
                    hospitalId
                )
            """)
            
        if let hospitalId = hospitalId {
            query = query.eq("hospitalId", value: hospitalId.uuidString)
        }
        
        let bookings: [BedBooking] = try await query
            .order("startDate", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        // Convert raw bookings to BedBookingWithDetails
        var bookingsWithDetails: [BedBookingWithDetails] = []
        for booking in bookings {
            do {
                let patient = try await fetchPatientDetails(patientId: booking.patientId)
                let bed = try await fetchBedDetails(bedId: booking.bedId)
                
                if let patient = patient, let bed = bed {
                    let bookingWithDetails = BedBookingWithDetails(
                        booking: booking,
                        patient: patient,
                        bed: bed
                    )
                    bookingsWithDetails.append(bookingWithDetails)
                }
            } catch {
                // If we couldn't load patient or bed details, log the error but continue processing
                print("Error loading details for booking \(booking.id): \(error)")
                continue
            }
        }
        
        return bookingsWithDetails
    } catch {
        print("Error loading bed bookings: \(error)")
        return [] // Return empty array instead of throwing
    }
}

private func fetchBedDetails(bedId: UUID) async throws -> Bed? {
    do {
        let beds: [Bed] = try await client
            .from("Bed")
            .select("""
                id,
                hospitalId,
                price,
                type,
                isAvailable
            """)
            .eq("id", value: bedId.uuidString)
            .execute()
            .value
        return beds.first
    } catch {
        print("Error fetching bed details for \(bedId): \(error)")
        return nil
    }
}

// Add function to create a bed booking
func createBedBooking(patientId: UUID, bedId: UUID, startDate: Date, endDate: Date) async throws {
    let booking: [String: AnyJSON] = [
        "id": .string(UUID().uuidString),
        "patientId": .string(patientId.uuidString),
        "bedId": .string(bedId.uuidString),
        "startDate": .string(ISO8601DateFormatter().string(from: startDate)),
        "endDate": .string(ISO8601DateFormatter().string(from: endDate)),
        "isAvailable": .bool(false)
    ]
    
    try await client
        .from("BedBooking")
        .insert(booking)
        .execute()
    
    // Update bed availability
    try await updateBedAvailability(bedId: bedId, isAvailable: false)
}

// Add function to get available beds by type
func getAvailableBedsByType(type: BedType, hospitalId: UUID? = nil) async throws -> [Bed] {
    var query = client
        .from("Bed")
        .select()
        .eq("type", value: type.rawValue)
        .eq("isAvailable", value: true)
    
    if let hospitalId = hospitalId {
        query = query.eq("hospitalId", value: hospitalId.uuidString)
    }
    
    let beds: [Bed] = try await query
        .execute()
        .value
    
    return beds
}

func getBedStatistics(hospitalId: UUID? = nil) async throws -> (total: Int, available: Int, byType: [BedType: (total: Int, available: Int)]) {
    do {
        // First try to fetch all beds
        let beds = try await fetchAllBeds(hospitalId: hospitalId)
        
        let total = beds.count
        let available = beds.filter { $0.isAvailable ?? false }.count
        
        var statsByType: [BedType: (total: Int, available: Int)] = [:]
        
        // Initialize stats for all bed types
        for type in [BedType.General, BedType.ICU, BedType.Personal] {
            let bedsOfType = beds.filter { $0.type == type }
            let totalOfType = bedsOfType.count
            let availableOfType = bedsOfType.filter { $0.isAvailable ?? false }.count
            statsByType[type] = (total: totalOfType, available: availableOfType)
        }
        
        return (total: total, available: available, byType: statsByType)
    } catch {
        print("Error fetching bed statistics: \(error)")
        
        // Return default stats with zeros
        let defaultStats: [BedType: (total: Int, available: Int)] = [
            .General: (total: 0, available: 0),
            .ICU: (total: 0, available: 0),
            .Personal: (total: 0, available: 0)
        ]
        
        return (total: 0, available: 0, byType: defaultStats)
    }
}
    func fetcInvoices(HospitalId : Hospital.ID  ) async throws -> [Invoice]  {
        do {
            let invoices : [Invoice] = try await client.from("Invoice").select("*").eq("HospitalId", value: HospitalId).execute().value
            print(invoices)
            return []
        }catch{
            print(error.localizedDescription)
        }
        return []
    }
}
