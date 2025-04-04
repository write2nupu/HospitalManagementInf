//
//  SupabaseController.swift
//  HospitalManagement
//
//  Created by Mariyo on 20/03/25.
//

import Foundation
import Supabase
// Add this import if TimeSlot is in a separate file
// import YourModuleName where TimeSlot is defined

// Add this import if AppointmentShift is in a separate module
// import YourModuleName

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
    func fetchPatientDetails(patientId: UUID) async throws -> Patient? {
        do {
            // Create a decoder with custom date decoding strategy
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try multiple date formats
                let dateFormatters = [
                    ISO8601DateFormatter(),
                    DateFormatter().apply { df in
                        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        df.locale = Locale(identifier: "en_US_POSIX")
                    },
                    DateFormatter().apply { df in
                        df.dateFormat = "yyyy-MM-dd"
                        df.locale = Locale(identifier: "en_US_POSIX")
                    }
                ]
                
                for formatter in dateFormatters {
                    if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ?? 
                       (formatter as? DateFormatter)?.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string \(dateString)"
                )
            }

            let patients: [Patient] = try await client
                .from("Patient")
                .select()
                .eq("id", value: patientId)
                .execute()
                .value

            print("Raw patient data received: \(patients)")
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
        
        // Store the patient ID in UserDefaults
        UserDefaults.standard.set(patient.id.uuidString, forKey: "currentPatientId")
        print("Stored patient ID in UserDefaults:", patient.id.uuidString)
        
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
            prescriptionId
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
func fetchPatientDetailsById(detailId: UUID) async throws -> PatientDetails? {
    print("Fetching patient details for detailId: \(detailId)")
    do {
        // First, let's check what's in the table
        print("Checking all records in Patientdetails table...")
        let allRecords = try await client
            .from("Patientdetails")
            .select("*")
            .execute()
        
        if let data = allRecords.data as? [[String: Any]] {
            print("All records in Patientdetails table:")
            data.forEach { record in
                if let detailId = record["detail_id"] as? String {
                    print("Found record with detail_id: \(detailId)")
                }
                print(record)
            }
        }
        
        // Now try to fetch the specific record
        let lowercaseUUID = detailId.uuidString.lowercased()
        print("Attempting to fetch specific record with detail_id: \(lowercaseUUID)")
        let response = try await client
            .from("Patientdetails")
            .select("""
                detail_id,
                blood_group,
                allergies,
                existing_medical_rec,
                current_medication,
                past_surgeries,
                emergency_contact
            """)
            .eq("detail_id", value: lowercaseUUID)
            .execute()
        
        // Handle raw Data response
        if let responseData = response.data as? Data {
            print("Got raw Data response, attempting to decode...")
            let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])
            print("Decoded JSON: \(jsonObject)")
            
            if let records = jsonObject as? [[String: Any]], !records.isEmpty {
                print("Found \(records.count) matching records")
                
                // Transform the response to match our model
                let transformedObject = records.map { dict -> [String: Any] in
                    var newDict = dict
                    if let detailId = dict["detail_id"] as? String {
                        newDict["id"] = detailId
                    }
                    if let medicalRec = dict["existing_medical_rec"] as? String {
                        newDict["existing_medical_record"] = medicalRec
                    }
                    return newDict
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: transformedObject, options: [])
                let details = try JSONDecoder().decode([PatientDetails].self, from: jsonData)
                print("Successfully decoded \(details.count) patient details")
                return details.first
            }
        } else if let jsonObject = response.data as? [[String: Any]], !jsonObject.isEmpty {
            print("Found matching patient details: \(jsonObject)")
            
            // Transform the response to match our model
            let transformedObject = jsonObject.map { dict -> [String: Any] in
                var newDict = dict
                if let detailId = dict["detail_id"] as? String {
                    newDict["id"] = detailId
                }
                if let medicalRec = dict["existing_medical_rec"] as? String {
                    newDict["existing_medical_record"] = medicalRec
                }
                return newDict
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: transformedObject, options: [])
            let details = try JSONDecoder().decode([PatientDetails].self, from: jsonData)
            print("Successfully decoded \(details.count) patient details")
            return details.first
        }
        
        print("No patient details found for detail_id: \(lowercaseUUID)")
        print("Response data type: \(type(of: response.data))")
        if let data = response.data as? Data {
            let str = String(data: data, encoding: .utf8) ?? "Could not convert to string"
            print("Response data as string: \(str)")
        } else {
            print("Response data content: \(response.data)")
        }
        return nil
    } catch {
        print("Error fetching patient details: \(error)")
        print("Detailed error: \(String(describing: error))")
        throw error
    }
}

// Helper for custom key decoding
private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

//    func savePrescription(_ prescription: PrescriptionData) async throws {
//        try await client
//            .from("Prescription")
//            .upsert(prescription)
//            .execute()
//    }

    // MARK: - Patient Operations
    func fetchPatientById(patientId: UUID) async throws -> Patient? {
        let patients: [Patient] = try await client
            .from("Patient")
            .select()
            .eq("id", value: patientId.uuidString)
            .execute()
            .value
        
        return patients.first
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
        
        // Store hospital ID in UserDefaults if available
        if let hospitalId = admin.hospital_id {
            print("Storing hospital ID in UserDefaults:", hospitalId.uuidString)
            UserDefaults.standard.set(hospitalId.uuidString, forKey: "currentHospitalId")
        }
        
        return admin
    }
    
    func fetchAdminProfile() async throws -> (Admin, Hospital)? {
        print("Fetching admin profile details")
        
        // Get current admin ID from UserDefaults
        guard let currentAdminId = UserDefaults.standard.string(forKey: "currentAdminId"),
              let adminUUID = UUID(uuidString: currentAdminId) else {
            print("No current admin ID found in UserDefaults")
            
            // If no admin ID in UserDefaults, try to get it from hospitalId
            if let hospitalIdString = UserDefaults.standard.string(forKey: "hospitalId"),
               let hospitalId = UUID(uuidString: hospitalIdString) {
                
                // Fetch hospital by ID
                let hospitals: [Hospital] = try await client
                    .from("Hospital")
                    .select("*")
                    .eq("id", value: hospitalId.uuidString)
                    .execute()
                    .value
                
                guard let hospital = hospitals.first,
                      let assignedAdminId = hospital.assigned_admin_id else {
                    print("No hospital or assigned admin found")
                    return nil
                }
                
                // Fetch admin by ID
                let admins: [Admin] = try await client
                    .from("Admin")
                    .select("*")
                    .eq("id", value: assignedAdminId.uuidString)
                    .execute()
                    .value
                
                if let admin = admins.first {
                    print("Found admin profile using hospital ID")
                    return (admin, hospital)
                }
            }
            
            return nil
        }
        
        // Fetch admin by ID
        let admins: [Admin] = try await client
            .from("Admin")
            .select("*")
            .eq("id", value: adminUUID.uuidString)
            .execute()
            .value
        
        guard let admin = admins.first else {
            print("Admin not found with ID: \(adminUUID)")
            return nil
        }
        
        // Fetch hospital using admin's hospital_id
        guard let hospitalId = admin.hospital_id else {
            print("Admin has no associated hospital ID")
            return nil
        }
        
        let hospitals: [Hospital] = try await client
            .from("Hospital")
            .select("*")
            .eq("id", value: hospitalId.uuidString)
            .execute()
            .value
        
        guard let hospital = hospitals.first else {
            print("Hospital not found with ID: \(hospitalId)")
            return nil
        }
        
        print("Successfully fetched admin profile and associated hospital")
        return (admin, hospital)
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
    func createBedBooking(patientId: UUID, bedId: UUID, hospitalId: UUID, startDate: Date, endDate: Date) async throws {
        let booking: [String: AnyJSON] = [
            "id": .string(UUID().uuidString),
            "patientId": .string(patientId.uuidString),
            "bedId": .string(bedId.uuidString),
            "hospitalId": .string(hospitalId.uuidString),
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
    
    // MARK: - Invoice Functions
    func fetchInvoicesByPatientId(patientId: UUID) async -> [Invoice] {
        do {
            let invoices: [Invoice] = try await client
                .from("Invoice")
                .select()
                .eq("patientid", value: patientId)
                .execute()
                .value
            
            print("Successfully fetched \(invoices.count) invoices for patient \(patientId)")
            return invoices
        } catch {
            print("Error fetching invoices: \(error)")
            return []
        }
    }
    
    func fetchAllInvoices() async -> [Invoice] {
        do {
            let invoices: [Invoice] = try await client
                .from("Invoice")
                .select()
                .execute()
                .value
            
            print("Successfully fetched \(invoices.count) invoices")
            return invoices
        } catch {
            print("Error fetching all invoices: \(error)")
            return []
        }
    }
    
    func createInvoice(invoice: Invoice) async throws {
        let dateFormatter = ISO8601DateFormatter()
        
        let invoiceData: [String: AnyJSON] = [
            "id": .string(invoice.id.uuidString),
            "createdAt": .string(dateFormatter.string(from: invoice.createdAt)),
            "patientid": .string(invoice.patientid.uuidString),
            "amount": .double(Double(invoice.amount)),
            "paymentType": .string(invoice.paymentType.rawValue),
            "status": .string(invoice.status.rawValue),
            "hospitalId": .string(invoice.hospitalId!.uuidString)
        ]
        
        try await client
            .from("Invoice")
            .insert(invoiceData)
            .execute()
        
        print("Invoice stored in database successfully")
    }
    
    func getBookingsByPatientId(patientId: UUID) async throws -> [BedBookingWithDetails] {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try parsing with the exact format from the database
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                
                // If that fails, try with ISO8601
                let iso8601Formatter = ISO8601DateFormatter()
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
            
            let query = client
                .from("BedBooking")
                .select("""
                id,
                patientId,
                bedId,
                hospitalId,
                startDate,
                endDate,
                isAvailable,
                Bed (
                    id,
                    type,
                    price,
                    hospitalId
                )
            """)
                .eq("patientId", value: patientId.uuidString)
                .order("startDate", ascending: false)
            
            let response = try await query.execute()
            let bookings = try decoder.decode([BedBooking].self, from: response.data)
            
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
                    print("Error loading details for booking \(booking.id): \(error)")
                    continue
                }
            }
            
            return bookingsWithDetails
        } catch {
            print("Error loading bed bookings: \(error)")
            throw error
        }
    }
    
    func createAppointment(appointment: Appointment, timeSlot: TimeSlot) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Use 24-hour format for database storage
        
        let appointmentData: [String: AnyJSON] = [
            "id": .string(appointment.id.uuidString),
            "patientId": .string(appointment.patientId.uuidString),
            "doctorId": .string(appointment.doctorId.uuidString),
            "date": .string(dateFormatter.string(from: timeSlot.startTime)),
            "status": .string(appointment.status.rawValue),
            "type": .string(appointment.type.rawValue),
            "prescriptionId": .null,
            "createdAt": .string(dateFormatter.string(from: Date()))
        ]
        
        try await client
            .from("Appointment")
            .insert(appointmentData)
            .execute()
    }
    
    func getBookedTimeSlots(doctorId: UUID, date: Date) async throws -> [TimeSlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let appointments: [Appointment] = try await client
            .from("Appointment")
            .select()
            .eq("doctorId", value: doctorId.uuidString)
            .gte("date", value: startOfDay)
            .lt("date", value: endOfDay)
            .execute()
            .value
        
        return appointments.map { appointment in
            TimeSlot(
                startTime: appointment.date,
                endTime: Calendar.current.date(byAdding: .minute, value: 30, to: appointment.date)!
            )
        }
    }
    
    //    func fetchAppointmentsForPatient(patientId: UUID) async throws -> [Appointment] {
    //        let appointments: [Appointment] = try await client
    //            .from("Appointment")
    //            .select()
    //            .eq("patientId", value: patientId.uuidString)
    //            .execute()
    //            .value
    //
    //        return appointments
    //    }
    
    func checkTimeSlotAvailability(doctorId: UUID, timeSlot: TimeSlot) async throws -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: timeSlot.startTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Get all appointments for this doctor on this date
        let appointments: [Appointment] = try await client
            .from("Appointment")
            .select()
            .eq("doctorId", value: doctorId.uuidString)
            .gte("date", value: dateFormatter.string(from: startOfDay))
            .lt("date", value: dateFormatter.string(from: calendar.date(byAdding: .day, value: 1, to: startOfDay)!))
            .execute()
            .value
        
        // Check if there's any overlap with existing appointments
        for appointment in appointments {
            let appointmentStart = appointment.date
            let appointmentEnd = calendar.date(byAdding: .minute, value: 30, to: appointmentStart)!
            
            if (timeSlot.startTime >= appointmentStart && timeSlot.startTime < appointmentEnd) ||
                (timeSlot.endTime > appointmentStart && timeSlot.endTime <= appointmentEnd) ||
                (timeSlot.startTime <= appointmentStart && timeSlot.endTime >= appointmentEnd) {
                return false
            }
        }
        
        return true
    }
    
    func getAvailableTimeSlots(doctorId: UUID, date: Date) async throws -> [TimeSlot] {
        // Generate all possible time slots for the date
        let allTimeSlots = TimeSlot.generateTimeSlots(for: date)
        
        // Create a mutable calendar
        var calendar = Calendar.current
        // Set the timezone
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        
        // Format dates for Supabase query
        let isoFormatter = ISO8601DateFormatter()
        
        // Get the start of the day for the appointment date
        let startOfDay = calendar.startOfDay(for: date)
        
        // Get all appointments for this doctor on this date
        let appointments: [Appointment] = try await client
            .from("Appointment")
            .select()
            .eq("doctorId", value: doctorId.uuidString)
            .gte("date", value: isoFormatter.string(from: startOfDay))
            .lt("date", value: isoFormatter.string(from: calendar.date(byAdding: .day, value: 1, to: startOfDay)!))
            .execute()
            .value
        
        // Create a list of booked time slots
        var bookedTimeSlots: [TimeSlot] = []
        for appointment in appointments {
            let appointmentStart = appointment.date
            let appointmentEnd = calendar.date(byAdding: .minute, value: 30, to: appointmentStart)!
            bookedTimeSlots.append(TimeSlot(startTime: appointmentStart, endTime: appointmentEnd))
        }
        
        // Filter out booked time slots
        let availableSlots = allTimeSlots.filter { slot in
            for bookedSlot in bookedTimeSlots {
                // Check for any kind of overlap
                if (slot.startTime >= bookedSlot.startTime && slot.startTime < bookedSlot.endTime) ||
                    (slot.endTime > bookedSlot.startTime && slot.endTime <= bookedSlot.endTime) ||
                    (slot.startTime <= bookedSlot.startTime && slot.endTime >= bookedSlot.endTime) {
                    return false
                }
            }
            return true
        }
        
        return availableSlots
    }
    
    func fetchEmergencyAppointments(patientId: UUID) async throws -> [Appointment] {
        let emergencyAppointments: [EmergencyAppointment] = try await client
            .from("EmergencyAppointment")
            .select()
            .eq("patientId", value: patientId.uuidString)
            .execute()
            .value
        
        // Convert EmergencyAppointment to Appointment
        return emergencyAppointments.map { emergency in
            Appointment(
                id: emergency.id,
                patientId: emergency.patientId,
                doctorId: UUID(), // Placeholder doctor ID
                date: Date(), // Current date since emergency is immediate
                status: emergency.status,
                createdAt: Date(),
                type: .Emergency,
                prescriptionId: nil
            )
        }
    }
    
    // Update the existing fetchAppointmentsForPatient function
    func fetchAppointmentsForPatient(patientId: UUID) async throws -> [Appointment] {
        async let regularAppointments: [Appointment] = client
            .from("Appointment")
            .select()
            .eq("patientId", value: patientId.uuidString)
            .execute()
            .value
        
        async let emergencyAppointments = fetchEmergencyAppointments(patientId: patientId)
        
        // Combine both types of appointments
        let (regular, emergency) = try await (regularAppointments, emergencyAppointments)
        return regular + emergency
    }
    
    func fetchDoctorById(doctorId: UUID) async throws -> Doctor? {
        let doctors: [Doctor] = try await client
            .from("Doctor")
            .select()
            .eq("id", value: doctorId.uuidString)
            .execute()
            .value
        
        return doctors.first
    }
    
    func cancelAppointment(appointmentId: UUID) async throws {
        try await client
            .from("Appointment")
            .update(["status": AppointmentStatus.cancelled.rawValue])
            .eq("id", value: appointmentId.uuidString)
            .execute()
    }
    
    func rescheduleAppointment(appointmentId: UUID, newDate: Date, newTime: String) async throws {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
        
        // Parse the time string (expecting format "HH:mm")
        let timeComponents = newTime.split(separator: ":")
        if let hour = Int(timeComponents[0]), let minute = Int(timeComponents[1]) {
            dateComponents.hour = hour
            dateComponents.minute = minute
        }
        
        let finalDate = calendar.date(from: dateComponents)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Use 24-hour format for database storage
        let dateString = dateFormatter.string(from: finalDate)
        
        try await client
            .from("Appointment")
            .update(["date": dateString])
            .eq("id", value: appointmentId.uuidString)
            .execute()
        
    }
        // MARK: - Doctor Leave Request Functions
        func fetchLeaveRequests(hospitalId: UUID) async throws -> [(leave: Leave, doctor: Doctor, department: Department?)] {
            print("Fetching leaves for hospital: \(hospitalId)")
            do {
                print("Executing Supabase query...")
                let leaves: [Leave] = try await client
                    .from("Leave")
                    .select("""
                    id,
                    doctorId,
                    hospitalId,
                    type,
                    reason,
                    startDate,
                    endDate,
                    status
                """)
                    .eq("hospitalId", value: hospitalId.uuidString)
                    .execute()
                    .value
                
                print("Successfully fetched \(leaves.count) leaves")
                
                var leaveDetails: [(leave: Leave, doctor: Doctor, department: Department?)] = []
                
                for leave in leaves {
                    // Fetch doctor details
                    let doctors: [Doctor] = try await client
                        .from("Doctor")
                        .select()
                        .eq("id", value: leave.doctorId.uuidString)
                        .execute()
                        .value
                    
                    guard let doctor = doctors.first else {
                        print("Doctor not found for leave: \(leave.id)")
                        continue
                    }
                    
                    // Fetch department details if available
                    var department: Department? = nil
                    if let departmentId = doctor.department_id {
                        let departments: [Department] = try await client
                            .from("Department")
                            .select()
                            .eq("id", value: departmentId.uuidString)
                            .execute()
                            .value
                        
                        department = departments.first
                    }
                    
                    leaveDetails.append((leave: leave, doctor: doctor, department: department))
                }
                
                return leaveDetails
            } catch {
                print("Error fetching leaves: \(error.localizedDescription)")
                print("Error details: \(String(describing: error))")
                throw error
            }
        }
        
        func updateLeaveStatus(leaveId: UUID, status: LeaveStatus) async throws {
            do{
                try await client
                    .from("Leave")
                    .update(["status": status.rawValue])
                    .eq("id", value: leaveId.uuidString)
                    .execute()
            }catch{
                print(error.localizedDescription)
            }
        }
        
        func getAffectedAppointments(doctorId: UUID, startDate: Date, endDate: Date) async throws -> Int {
            do{
                let appointments: [Appointment] = try await client
                    .from("Appointment")
                    .select()
                    .eq("doctorId", value: doctorId.uuidString)
                    .eq("status", value: AppointmentStatus.scheduled.rawValue)
                    .gte("date", value: startDate)
                    .lte("date", value: endDate)
                    .execute()
                    .value
                
                return appointments.count
            }catch{
                print(error.localizedDescription)
                throw error
            }
            
        }
    
    func createEmergencyAppointment(_ appointment: EmergencyAppointment) async throws {
        // Get current patient ID from UserDefaults
        guard let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
              let patientId = UUID(uuidString: patientIdString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Patient ID not found"])
        }
        
        let appointmentData: [String: AnyJSON] = [
            "id": .string(appointment.id.uuidString),
            "patientId": .string(patientId.uuidString),
            "hospitalId": .string(appointment.hospitalId.uuidString),
            "status": .string(appointment.status.rawValue),
            "description": .string(appointment.description)
        ]
        
        do {
            try await client
                .from("EmergencyAppointment")
                .insert(appointmentData)
                .execute()
            
            print("Emergency appointment created successfully")
        } catch let error as PostgrestError {
            print("Postgrest error: \(error)")
            throw error
        } catch {
            print("Unexpected error: \(error)")
            throw error
        }
    }
    
    func fetchEmergencyRequests(hospitalId: UUID) async throws -> [EmergencyAppointment] {
        print("Fetching emergency requests for hospital: \(hospitalId)")
        do {
            let requests: [EmergencyAppointment] = try await client
                .from("EmergencyAppointment")
                .select("""
                    id,
                    patientId,
                    hospitalId,
                    status,
                    description
                """)
                .eq("hospitalId", value: hospitalId.uuidString)
                .execute()
                .value
            
            print("Successfully fetched \(requests.count) emergency requests")
            return requests
        } catch {
            print("Error fetching emergency requests: \(error)")
            throw error
        }
    }

    func getEmergencyDepartment(hospitalId: UUID) async throws -> Department {
        print("Fetching emergency department for hospital: \(hospitalId)")
        do {
            let departments: [Department] = try await client
                .from("Department")
                .select()
                .eq("hospital_id", value: hospitalId.uuidString)
                .eq("name", value: "Emergency")
                .execute()
                .value
            
            guard let emergencyDepartment = departments.first else {
                throw NSError(domain: "Hospital", code: 404, userInfo: [NSLocalizedDescriptionKey: "Emergency department not found"])
            }
            
            return emergencyDepartment
        } catch {
            print("Error fetching emergency department: \(error)")
            throw error
        }
    }

    func getEmergencyDoctors(departmentId: UUID) async throws -> [Doctor] {
        print("Fetching doctors for emergency department: \(departmentId)")
        do {
            let doctors: [Doctor] = try await client
                .from("Doctor")
                .select()
                .eq("department_id", value: departmentId.uuidString)
                .eq("is_active", value: true)
                .execute()
                .value
            
            return doctors
        } catch {
            print("Error fetching emergency doctors: \(error)")
            throw error
        }
    }

    func assignEmergencyDoctor(emergencyAppointment: EmergencyAppointment, doctorId: UUID) async throws {
        print("Assigning doctor \(doctorId) to emergency appointment \(emergencyAppointment.id)")
        
        // First update the emergency appointment status
        let updateData: [String: AnyJSON] = [
            "status": .string("Completed")  // Update to completed when doctor is assigned
        ]
        
        try await client
            .from("EmergencyAppointment")
            .update(updateData)
            .eq("id", value: emergencyAppointment.id.uuidString)
            .execute()
        
        // Create a regular appointment for tracking
        let appointmentData: [String: AnyJSON] = [
            "id": .string(UUID().uuidString),
            "patientId": .string(emergencyAppointment.patientId.uuidString),
            "doctorId": .string(doctorId.uuidString),
            "date": .string(ISO8601DateFormatter().string(from: Date())),
            "status": .string(AppointmentStatus.scheduled.rawValue),
            "type": .string(AppointmentType.Emergency.rawValue),
            "createdAt": .string(ISO8601DateFormatter().string(from: Date())),
            "prescriptionId": .null  // Set prescriptionId as null initially
        ]
        
        try await client
            .from("Appointment")
            .insert(appointmentData)
            .execute()
        
        print("Successfully assigned doctor and created appointment")
    }
}

// MARK: - Leave Management
extension SupabaseController {
    func applyForLeave(_ leave: Leave) async throws {
        let dateFormatter = ISO8601DateFormatter()
        let leaveData = LeaveRequest(
            id: leave.id,
            doctorId: leave.doctorId,
            hospitalId: leave.hospitalId,
            type: leave.type.rawValue,
            reason: leave.reason,
            startDate: dateFormatter.string(from: leave.startDate),
            endDate: dateFormatter.string(from: leave.endDate),
            status: leave.status.rawValue
        )
        
        try await client
            .from("Leave")
            .insert(leaveData)
            .execute()
    }
    
    func fetchPendingLeave(doctorId: UUID) async throws -> Leave? {
        let leaves: [LeaveResponse] = try await client
            .from("Leave")
            .select()
            .eq("doctorId", value: doctorId.uuidString)
            .eq("status", value: LeaveStatus.pending.rawValue)
            .order("startDate", ascending: true)
            .limit(1)
            .execute()
            .value
        
        guard let leaveResponse = leaves.first else { return nil }
        
        let dateFormatter = ISO8601DateFormatter()
        return Leave(
            id: leaveResponse.id,
            doctorId: leaveResponse.doctorId,
            hospitalId: leaveResponse.hospitalId,
            type: LeaveType(rawValue: leaveResponse.type) ?? .sickLeave,
            reason: leaveResponse.reason,
            startDate: dateFormatter.date(from: leaveResponse.startDate) ?? Date(),
            endDate: dateFormatter.date(from: leaveResponse.endDate) ?? Date(),
            status: LeaveStatus(rawValue: leaveResponse.status) ?? .pending
        )
    }
    
    func fetchAllLeaves(doctorId: UUID) async throws -> [Leave] {
        let leaves: [LeaveResponse] = try await client
            .from("Leave")
            .select()
            .eq("doctorId", value: doctorId.uuidString)
            .order("startDate", ascending: false)
            .execute()
            .value
        
        let dateFormatter = ISO8601DateFormatter()
        return leaves.map { leaveResponse in
            Leave(
                id: leaveResponse.id,
                doctorId: leaveResponse.doctorId,
                hospitalId: leaveResponse.hospitalId,
                type: LeaveType(rawValue: leaveResponse.type) ?? .sickLeave,
                reason: leaveResponse.reason,
                startDate: dateFormatter.date(from: leaveResponse.startDate) ?? Date(),
                endDate: dateFormatter.date(from: leaveResponse.endDate) ?? Date(),
                status: LeaveStatus(rawValue: leaveResponse.status) ?? .pending
            )
        }
    }
}

// MARK: - Leave Data Models
private struct LeaveRequest: Codable {
    let id: UUID
    let doctorId: UUID
    let hospitalId: UUID
    let type: String
    let reason: String
    let startDate: String
    let endDate: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case doctorId = "doctorId"
        case hospitalId = "hospitalId"
        case type
        case reason
        case startDate = "startDate"
        case endDate = "endDate"
        case status
    }
}

private struct LeaveResponse: Codable {
    let id: UUID
    let doctorId: UUID
    let hospitalId: UUID
    let type: String
    let reason: String
    let startDate: String
    let endDate: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case doctorId = "doctorId"
        case hospitalId = "hospitalId"
        case type
        case reason
        case startDate = "startDate"
        case endDate = "endDate"
        case status
    }
}

// MARK: - Lab Test Booking Functions
extension SupabaseController {
    func bookLabTest(
        tests: [LabTest.LabTestName],
        prescriptionId: UUID?,
        testDate: Date,
        paymentMethod: PaymentOption,
        hospitalId: UUID
    ) async throws {
        print("📝 Creating lab test booking...")
        
        // Create a single record for all tests
        var labTestData: [String: AnyJSON] = [
            "bookingId": .string(UUID().uuidString),
            "testName": .array(tests.map { .string($0.rawValue) }),  // Store test names as an array
            "status": .string(LabTest.TestStatus.pending.rawValue),
            "testDate": .string(testDate.ISO8601Format()),
            "testValue": .double(0.0),
            // Calculate total price for all tests
            "labTestPrice": .double(Double(tests.reduce(0) { $0 + $1.price })),
            "hospitalid": .string(hospitalId.uuidString)  // Add hospitalId directly
        ]
        
        // Add patientId if available
        if let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId") {
            labTestData["patientid"] = .string(patientIdString)
        }
        
        // Add prescriptionId if available
        if let prescriptionId = prescriptionId {
            labTestData["prescriptionId"] = .string(prescriptionId.uuidString)
        }
        
        print("Attempting to insert lab test with data: \(labTestData)")
        try await client
            .from("LabTest")
            .insert([labTestData])  // Insert a single record
            .execute()
        print("✅ Lab test booking created successfully!")
    }
    
    func fetchLabTests(patientId: UUID? = nil, hospitalId: UUID? = nil) async throws -> [(id: UUID, testName: String, testDate: Date, status: String, doctorName: String?, diagnosis: String?)] {
        print("🔍 Starting fetchLabTests function")
        print("Parameters - patientId: \(patientId?.uuidString ?? "nil"), hospitalId: \(hospitalId?.uuidString ?? "nil")")
        
        var query = client
            .from("LabTest")
            .select("""
                bookingId,
                testName,
                testDate,
                status,
                prescriptionId,
                Prescription:prescriptionId (
                    doctorId,
                    diagnosis,
                    Doctor:doctorId (
                        full_name
                    )
                )
            """)
        
        if let patientId = patientId {
            query = query.eq("patientid", value: patientId.uuidString)
            print("Added patient filter: \(patientId.uuidString)")
        }
        
        if let hospitalId = hospitalId {
            query = query.eq("hospitalid", value: hospitalId.uuidString)
            print("Added hospital filter: \(hospitalId.uuidString)")
        }
        
        print("Executing Supabase query...")
        let response = try await query
            .order("testDate", ascending: false)
            .execute()
        
        print("Response received")
        print("Raw response: \(String(describing: response.data))")
        
        // Try to handle different response formats
        var jsonArray: [[String: Any]] = []
        
        if let data = response.data as? Data {
            // If response is Data, try to decode it
            print("Response is Data type, attempting to decode...")
            jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        } else if let array = response.data as? [[String: Any]] {
            // If response is already an array of dictionaries
            print("Response is already Array type")
            jsonArray = array
        } else {
            print("Unexpected response type: \(type(of: response.data))")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        print("Processing \(jsonArray.count) lab tests")
        
        return try jsonArray.map { json -> (id: UUID, testName: String, testDate: Date, status: String, doctorName: String?, diagnosis: String?) in
            print("Processing lab test JSON: \(json)")
            
            // Extract booking ID
            guard let bookingIdString = json["bookingId"] as? String,
                  let bookingId = UUID(uuidString: bookingIdString) else {
                print("Invalid booking ID format")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid booking ID"])
            }
            
            // Parse test names
            var testName = ""
            if let testNameArray = json["testName"] as? [String] {
                // If it's already an array
                testName = testNameArray.joined(separator: ", ")
            } else if let testNameString = json["testName"] as? String {
                // If it's a JSON string, try to parse it
                do {
                    if let testNameData = testNameString.data(using: .utf8),
                       let testNames = try? JSONDecoder().decode([String].self, from: testNameData) {
                        testName = testNames.joined(separator: ", ")
                    } else {
                        // If not valid JSON, use the string as is
                        testName = testNameString
                    }
                }
            }
            
            // Parse date with multiple format attempts
            let dateFormatters = [
                DateFormatter().apply { df in
                    df.dateFormat = "yyyy-MM-dd"
                    df.timeZone = TimeZone(identifier: "UTC")
                },
                DateFormatter().apply { df in
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    df.timeZone = TimeZone(identifier: "UTC")
                },
                ISO8601DateFormatter()
            ]
            
            let testDateString = json["testDate"] as? String ?? ""
            print("Attempting to parse date: \(testDateString)")
            
            var testDate: Date?
            for formatter in dateFormatters {
                if let date = (formatter as? DateFormatter)?.date(from: testDateString) ?? 
                   (formatter as? ISO8601DateFormatter)?.date(from: testDateString) {
                    testDate = date
                    break
                }
            }
            
            guard let finalTestDate = testDate else {
                print("Failed to parse date: \(testDateString)")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid date format"])
            }
            
            // Extract status
            let status = json["status"] as? String ?? "Pending"
            
            // Extract prescription data
            var doctorName: String? = nil
            var diagnosis: String? = nil
            
            if let prescription = json["Prescription"] as? [String: Any] {
                diagnosis = prescription["diagnosis"] as? String
                if let doctor = prescription["Doctor"] as? [String: Any] {
                    doctorName = doctor["full_name"] as? String
                }
            }
            
            print("Successfully parsed test - ID: \(bookingId), Doctor: \(doctorName ?? "nil"), Diagnosis: \(diagnosis ?? "nil")")
            
            return (
                id: bookingId,
                testName: testName,
                testDate: finalTestDate,
                status: status,
                doctorName: doctorName,
                diagnosis: diagnosis
            )
        }
    }
    
    func updateLabTestStatus(testId: UUID, status: LabTest.TestStatus) async throws {
        try await client
            .from("LabTest")
            .update(["status": status.rawValue])
            .eq("id", value: testId.uuidString)
            .execute()
    }

    func updateLabTestValue(testId: UUID, testValue: Double, testComponents: [String]? = nil) async throws {
        print("📝 Updating lab test value for test ID: \(testId)")
        
        var updateData: [String: AnyJSON] = [
            "testValue": .double(testValue),
            "status": .string(LabTest.TestStatus.completed.rawValue)  // Update status to completed when value is added
        ]
        
        // Add test components if provided
        if let components = testComponents {
            updateData["testComponents"] = .array(components.map { .string($0) })
        }
        
        try await client
            .from("LabTest")
            .update(updateData)
            .eq("bookingId", value: testId.uuidString)  // Use bookingId as that's our primary key
            .execute()
        
        print("✅ Lab test value updated successfully!")
    }

    // Add a function to fetch a single lab test with its values
    func fetchLabTestWithValue(testId: UUID) async throws -> (testName: [String], testValue: Double, testComponents: [String]?, status: String) {
        print("🔍 Fetching lab test details for ID: \(testId)")
        
        let response = try await client
            .from("LabTest")
            .select("""
                testName,
                testValue,
                testComponents,
                status
            """)
            .eq("bookingId", value: testId.uuidString)
            .execute()
        
        guard let json = (response.data as? [[String: Any]])?.first else {
            throw NSError(domain: "LabTest", code: 404, userInfo: [NSLocalizedDescriptionKey: "Lab test not found"])
        }
        
        // Parse test names
        var testNames: [String] = []
        if let testNameArray = json["testName"] as? [String] {
            testNames = testNameArray
        } else if let testNameString = json["testName"] as? String,
                  let data = testNameString.data(using: .utf8),
                  let decodedArray = try? JSONDecoder().decode([String].self, from: data) {
            testNames = decodedArray
        }
        
        let testValue = (json["testValue"] as? Double) ?? 0.0
        let testComponents = json["testComponents"] as? [String]
        let status = (json["status"] as? String) ?? LabTest.TestStatus.pending.rawValue
        
        return (testNames, testValue, testComponents, status)
    }
}

// Update LabTestResult to match your schema with array of test names
public struct LabTestResult: Codable {
    let bookingId: UUID
    let testName: [String]   // Array of test names
    let status: String     
    let testDate: Date     
    let testValue: Float   
    let testComponents: [String]  
    let labTestPrice: Float  
    
    enum CodingKeys: String, CodingKey {
        case bookingId
        case testName
        case status
        case testDate
        case testValue
        case testComponents
        case labTestPrice
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        bookingId = try container.decode(UUID.self, forKey: .bookingId)
        
        // Handle testName as an array
        if let singleTest = try? container.decode(String.self, forKey: .testName) {
            // If it's a single string, wrap it in an array
            testName = [singleTest]
        } else {
            // If it's already an array, decode it directly
            testName = try container.decode([String].self, forKey: .testName)
        }
        
        status = try container.decode(String.self, forKey: .status)
        testValue = try container.decode(Float.self, forKey: .testValue)
        testComponents = try container.decode([String].self, forKey: .testComponents)
        labTestPrice = try container.decode(Float.self, forKey: .labTestPrice)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = try? container.decode(String.self, forKey: .testDate),
           let date = dateFormatter.date(from: dateString) {
            testDate = date
        } else {
            testDate = Date()
        }
    }
}



// MARK: - Appointment Management
extension SupabaseController {
    func updateAppointmentStatus(appointmentId: UUID, status: AppointmentStatus) async throws {
        try await client
            .from("Appointment")
            .update(["status": status.rawValue])
            .eq("id", value: appointmentId.uuidString)
            .execute()
    }
    func cancelAppointmentsDuringLeave(doctorId: UUID, startDate: Date, endDate: Date) async throws {
        // Fetch all scheduled appointments during the leave period
        let appointments: [Appointment] = try await client
            .from("Appointment")
            .select()
            .eq("doctorId", value: doctorId.uuidString)
            .eq("status", value: AppointmentStatus.scheduled.rawValue)
            .gte("date", value: startDate)
            .lte("date", value: endDate)
            .execute()
            .value
        
        // Update status to cancelled for all affected appointments
        for appointment in appointments {
            try await client
                .from("Appointment")
                .update(["status": AppointmentStatus.cancelled.rawValue])
                .eq("id", value: appointment.id.uuidString)
                .execute()
        }
    }

}
// Helper extension for formatter configuration
extension DateFormatter {
    func apply(_ config: (DateFormatter) -> Void) -> DateFormatter {
        config(self)
        return self

    }
}

extension SupabaseController {
    func fetchHospitalLabTests(hospitalId: UUID) async throws -> [LabReport] {
        print("🔍 Fetching lab tests for hospital: \(hospitalId)")
        
        let response = try await client
            .from("LabTest")
            .select("""
                bookingId,
                testName,
                testDate,
                status,
                Patient!inner (
                    fullname
                )
            """)
            .eq("hospitalid", value: hospitalId.uuidString)
            .order("testDate", ascending: false)
            .execute()
        
        print("Response received: \(String(describing: response.data))")
        
        var jsonArray: [[String: Any]] = []
        if let dataAsArray = response.data as? [[String: Any]] {
            print("Data is array of dictionaries")
            jsonArray = dataAsArray
        } else if let dataAsData = response.data as? Data {
            print("Data is raw Data type")
            jsonArray = try JSONSerialization.jsonObject(with: dataAsData) as? [[String: Any]] ?? []
        } else {
            print("Unexpected data type: \(type(of: response.data))")
            throw NSError(domain: "SupabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        if jsonArray.isEmpty {
            print("No lab tests found")
            return []
        }
        
        print("Processing \(jsonArray.count) lab tests")
        
        return jsonArray.compactMap { json -> LabReport? in
            guard let bookingId = UUID(uuidString: json["bookingId"] as? String ?? ""),
                  let patient = json["Patient"] as? [String: Any],
                  let patientName = patient["fullname"] as? String else {
                print("Failed to parse essential data for a lab test")
                return nil
            }
            
            // Parse test names
            var testNames: [String] = []
            if let testNameArray = json["testName"] as? [String] {
                testNames = testNameArray
            } else if let testNameString = json["testName"] as? String,
                      let data = testNameString.data(using: .utf8),
                      let decodedArray = try? JSONDecoder().decode([String].self, from: data) {
                testNames = decodedArray
            }
            
            // Parse the test date
            let testDateString = json["testDate"] as? String ?? ""
            let dateFormatters = [
                ISO8601DateFormatter(),
                DateFormatter().apply { df in
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    df.timeZone = TimeZone(identifier: "UTC")
                },
                DateFormatter().apply { df in
                    df.dateFormat = "yyyy-MM-dd"
                    df.timeZone = TimeZone(identifier: "UTC")
                }
            ]
            
            let testDate = dateFormatters.compactMap { formatter in
                (formatter as? ISO8601DateFormatter)?.date(from: testDateString) ??
                (formatter as? DateFormatter)?.date(from: testDateString)
            }.first ?? Date()
            
            // Convert status to ReportStatus
            let statusString = json["status"] as? String ?? "pending"
            let reportStatus: ReportStatus
            switch statusString.lowercased() {
            case "completed":
                reportStatus = .completed
            default:
                reportStatus = .pending
            }
            
            return LabReport(
                id: bookingId,
                patientName: patientName,
                testType: testNames.joined(separator: ", "),
                requestDate: testDate,
                status: reportStatus,
                doctorName: "N/A" // Since we don't need doctor name, set it to N/A
            )
        }
    }
}
