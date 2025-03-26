//
//  DataController.swift
//  HospitalManagement
//
//  Created by Mariyo on 19/03/25.
//

import Foundation
import SwiftUI

enum DataError: Error {
    case invalidData
    case recordNotFound
    case saveFailed
    case loadFailed
    case alreadyInactive
    case alreadyActive
}

@MainActor
final class HospitalManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var superAdmins: [SuperAdmin] = []
    @Published var admins: [Admin] = []
    @Published var hospitals: [Hospital] = []
    @Published var departments: [Department] = []
    @Published var doctors: [Doctor] = []
    @Published var patients: [Patient] = []
    @Published var patientDetails: [PatientDetails] = []
    @Published var showUserProfile = false
    
    // MARK: - Save Keys
    private let superAdminsKey = "SavedSuperAdmins"
    private let adminsKey = "SavedAdmins"
    private let hospitalsKey = "SavedHospitals"
    private let departmentsKey = "SavedDepartments"
    private let doctorsKey = "SavedDoctors"
    private let patientsKey = "SavedPatients"
    private let patientDetailsKey = "SavedPatientDetails"
    
    init() {
        loadAllData()
    }
    
    // MARK: - Hospital Management
    
    func addHospital(_ hospital: Hospital) throws {
        guard !hospital.name.isEmpty else { throw DataError.invalidData }
        hospitals.append(hospital)
        try saveHospitals()
    }
    
    func updateHospital(_ hospital: Hospital) throws {
        guard let index = hospitals.firstIndex(where: { $0.id == hospital.id }) else {
            throw DataError.recordNotFound
        }
        hospitals[index] = hospital
        try saveHospitals()
    }
    
    func deactivateHospital(_ hospital: Hospital) throws {
        guard let index = hospitals.firstIndex(where: { $0.id == hospital.id }) else {
            throw DataError.recordNotFound
        }
        
        guard hospitals[index].is_active else {
            throw DataError.alreadyInactive
        }
        
        var updatedHospital = hospitals[index]
        updatedHospital.is_active = false
        hospitals[index] = updatedHospital
        
        try saveHospitals()
    }
    
    func reactivateHospital(_ hospital: Hospital) throws {
        guard let index = hospitals.firstIndex(where: { $0.id == hospital.id }) else {
            throw DataError.recordNotFound
        }
        
        guard !hospitals[index].is_active else {
            throw DataError.alreadyActive
        }
        
        var updatedHospital = hospitals[index]
        updatedHospital.is_active = true
        hospitals[index] = updatedHospital
        
        try saveHospitals()
    }
    
    // MARK: - Doctor Management
    
    func addDoctor(_ doctor: Doctor) throws {
        guard !doctor.full_name.isEmpty else { throw DataError.invalidData }
        doctors.append(doctor)
        try saveDoctors()
    }
    
    func updateDoctor(_ doctor: Doctor) throws {
        guard let index = doctors.firstIndex(where: { $0.id == doctor.id }) else {
            throw DataError.recordNotFound
        }
        doctors[index] = doctor
        try saveDoctors()
    }
    
    func deactivateDoctor(_ doctor: Doctor) throws {
        guard let index = doctors.firstIndex(where: { $0.id == doctor.id }) else {
            throw DataError.recordNotFound
        }
        
        guard doctors[index].is_active else {
            throw DataError.alreadyInactive
        }
        
        var updatedDoctor = doctors[index]
        updatedDoctor.is_active = false
        doctors[index] = updatedDoctor
        
        try saveDoctors()
    }
    
    // MARK: - Admin Management
    
    func addAdmin(_ admin: Admin) throws {
        guard !admin.full_name.isEmpty else { throw DataError.invalidData }
        admins.append(admin)
        try saveAdmins()
    }
    
    func updateAdmin(_ admin: Admin) throws {
        guard let index = admins.firstIndex(where: { $0.id == admin.id }) else {
            throw DataError.recordNotFound
        }
        admins[index] = admin
        try saveAdmins()
    }
    
    // MARK: - Department Management
    
    func addDepartment(_ department: Department) throws {
        guard !department.name.isEmpty else { throw DataError.invalidData }
        departments.append(department)
        try saveDepartments()
    }
    
    func updateDepartment(_ department: Department) throws {
        guard let index = departments.firstIndex(where: { $0.id == department.id }) else {
            throw DataError.recordNotFound
        }
        departments[index] = department
        try saveDepartments()
    }
    
    // MARK: - Utility Functions
    
    func generateRandomPassword() -> String {
        let digits = "0123456789"
        return String((0..<6).map { _ in digits.randomElement()! })
    }
    
    func getDoctorsByHospital(hospitalId: UUID) -> [Doctor] {
        return doctors.filter { $0.hospital_id == hospitalId && $0.is_active }
    }
    
    func getDepartmentsByHospital(hospitalId: UUID) -> [Department] {
        return departments.filter { $0.hospital_id == hospitalId }
    }
    
    func getAdminByHospital(hospitalId: UUID) -> Admin? {
        return admins.first { $0.hospital_id == hospitalId }
    }
    
    // MARK: - Data Persistence
    
    private func loadAllData() {
        loadHospitals()
        loadDoctors()
        loadAdmins()
        loadDepartments()
        loadPatients()
        loadPatientDetails()
        loadSuperAdmins()
    }
    
    private func saveHospitals() throws {
        try save(hospitals, forKey: hospitalsKey)
    }
    
    private func saveDoctors() throws {
        try save(doctors, forKey: doctorsKey)
    }
    
    private func saveAdmins() throws {
        try save(admins, forKey: adminsKey)
    }
    
    private func saveDepartments() throws {
        try save(departments, forKey: departmentsKey)
    }
    
    private func save<T: Encodable>(_ items: T, forKey key: String) throws {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            throw DataError.saveFailed
        }
    }
    
    private func loadHospitals() {
        load(hospitalsKey) { [weak self] (hospitals: [Hospital]) in
            self?.hospitals = hospitals
        }
    }
    
    private func loadDoctors() {
        load(doctorsKey) { [weak self] (doctors: [Doctor]) in
            self?.doctors = doctors
        }
    }
    
    private func loadAdmins() {
        load(adminsKey) { [weak self] (admins: [Admin]) in
            self?.admins = admins
        }
    }
    
    private func loadDepartments() {
        load(departmentsKey) { [weak self] (departments: [Department]) in
            self?.departments = departments
        }
    }
    
    private func loadPatients() {
        load(patientsKey) { [weak self] (patients: [Patient]) in
            self?.patients = patients
        }
    }
    
    private func loadPatientDetails() {
        load(patientDetailsKey) { [weak self] (details: [PatientDetails]) in
            self?.patientDetails = details
        }
    }
    
    private func loadSuperAdmins() {
        load(superAdminsKey) { [weak self] (superAdmins: [SuperAdmin]) in
            self?.superAdmins = superAdmins
        }
    }
    
    private func load<T: Decodable>(_ key: String, completion: @escaping (T) -> Void) {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        
        do {
            let items = try JSONDecoder().decode(T.self, from: data)
            completion(items)
        } catch {
            print("Error loading data for key \(key): \(error.localizedDescription)")
        }
    }
}



