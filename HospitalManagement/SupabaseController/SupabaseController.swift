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
            
            // Sign in to get a valid session
            return try await signIn(email: email, password: password)
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
            
            // Extract values from userMetadata, converting numbers to strings if needed
            let fullName = userMetadata["full_name"] as? String ?? ""
            let phoneNumber: String
            if let phoneNum = userMetadata["phone_number"] {
                if let numStr = phoneNum as? String {
                    phoneNumber = numStr
                } else if let num = phoneNum as? Int {
                    phoneNumber = String(num)
                } else if let num = phoneNum as? Double {
                    phoneNumber = String(Int(num))
                } else {
                    phoneNumber = ""
                }
            } else {
                phoneNumber = ""
            }
            let role = userMetadata["role"] as? String ?? "patient"
            
            print("Extracted metadata - fullName: \(fullName), phoneNumber: \(phoneNumber), role: \(role)")
            
            // Try to fetch existing user first
            do {
                let existingUser = try await client.database
                    .from("Users")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .single()
                    .execute()
                
                // If user exists, return the existing user
                if let userData = try? decoder.decode(User.self, from: existingUser.data) {
                    print("Found existing user with role:", userData.role)
                    return userData
                }
            } catch {
                print("No existing user found, creating new user")
            }
            
            // Create user dictionary for new user
            let userDict: [String: AnyJSON] = [
                "id": .string(userId.uuidString),
                "email": .string(authResponse.user.email ?? email),
                "full_name": .string(fullName),
                "phone_number": .string(phoneNumber),
                "role": .string(role),
                "is_first_login": .bool(true),
                "is_active": .bool(true),
                "created_at": .string(currentDate),
                "updated_at": .string(currentDate)
            ]
            
            print("Creating new user with data:", userDict)
            
            // Insert new user
            let insertResponse = try await client.database
                .from("Users")
                .insert(userDict)
                .select()
                .single()
                .execute()
            
            return try decoder.decode(User.self, from: insertResponse.data)
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
            
                .from("Doctors")
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
            
                .from("Hospitals")
                .select()
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
            
                .from("Doctors")
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
                .from("Admins")
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
                .from("Departments")
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
                .from("Doctors")
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
    func addHospital(_ hospital: Hospital) async {
        do {
            try await client
                .from("Hospitals")
                .insert(hospital)
                .execute()
            print("Hospital added successfully!")
        } catch {
            print("Error adding hospital: \(error)")
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
    
    // MARK: - Fetch Doctor Available Slots
    //    func fetchDoctorSlots(doctorId: UUID) async -> [String] {
    //        do {
    //            let slots: [DoctorSlot] = try await client
    //                .from("DoctorSlots")
    //                .select()
    //                .eq("doctorId", value: doctorId)
    //                .execute()
    //                .value
    //            return slots.map { $0.slotTime }
    //        } catch {
    //            print("Error fetching doctor slots: \(error)")
    //            return []
    //        }
    //    }
    
    // MARK: - Fetch Doctor Languages
    //    func fetchDoctorLanguages(doctorId: UUID) async -> [String] {
    //        do {
    //            let languages: [DoctorLanguage] = try await client
    //                .from("DoctorLanguages")
    //                .select()
    //                .eq("doctorId", value: doctorId)
    //                .execute()
    //                .value
    //            return languages.map { $0.language }
    //        } catch {
    //            print("Error fetching doctor languages: \(error)")
    //            return []
    //        }
    //    }
    //}
    
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
}
