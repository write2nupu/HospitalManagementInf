//
//  dummy.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 19/03/25.
//

//
//  Hospital.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 19/03/25.
//


struct Hospital {
    var name: String
    var location: String
    var departments: [Department]
}

let hospital: [Hospital] = [
    Hospital(name: "Apollo Hospital", location: "Delhi", departments: [
        Department(name: "Cardiology", doctors: [
            Doctor(name: "Dr. Anubhav Dubey", specialization: "Cardiologist", qualifications: "MBBS, MD", experience: 10, hospitalAffiliations: ["Apollo"], consultationFee: 500.0, phoneNumber: "9876543210", email: "doctor1@example.com", availableSlots: ["Monday: 10AM - 12PM", "Wednesday: 2PM - 4PM"], languagesSpoken: ["English", "Hindi"]),
            Doctor(name: "Dr. Ritu Sharma", specialization: "Cardiologist", qualifications: "MBBS, DM", experience: 8, hospitalAffiliations: ["Apollo"], consultationFee: 400.0, phoneNumber: "9876543211", email: "doctor2@example.com", availableSlots: ["Tuesday: 9AM - 11AM"], languagesSpoken: ["English", "Hindi"])
        ]),
        Department(name: "Orthopedics", doctors: [
            Doctor(name: "Dr. Manish Kumar", specialization: "Orthopedic Surgeon", qualifications: "MBBS, MS", experience: 12, hospitalAffiliations: ["Apollo"], consultationFee: 700.0, phoneNumber: "9876543212", email: "doctor3@example.com", availableSlots: ["Friday: 1PM - 3PM"], languagesSpoken: ["English", "Punjabi"])
        ])
    ]),
    
    Hospital(name: "Fortis Hospital", location: "Mumbai", departments: [
        Department(name: "Neurology", doctors: [
            Doctor(name: "Dr. Kavita Mishra", specialization: "Neurologist", qualifications: "MBBS, DM", experience: 15, hospitalAffiliations: ["Fortis"], consultationFee: 800.0, phoneNumber: "9876543213", email: "doctor4@example.com", availableSlots: ["Monday: 2PM - 5PM"], languagesSpoken: ["English", "Marathi"]),
            Doctor(name: "Dr. Rajiv Bansal", specialization: "Neurologist", qualifications: "MBBS, MD", experience: 11, hospitalAffiliations: ["Fortis"], consultationFee: 600.0, phoneNumber: "9876543214", email: "doctor5@example.com", availableSlots: ["Thursday: 10AM - 12PM"], languagesSpoken: ["English", "Hindi"])
        ])
    ])
]

struct Department {
    var name: String
    var doctors: [Doctor]
}

let doctors: [Doctor] = [
    Doctor(name: "Dr. Anubhav Dubey", specialization: "Cardiologist", qualifications: "MBBS, MD", experience: 10, hospitalAffiliations: ["Apollo"], consultationFee: 500.0, phoneNumber: "9876543210", email: "doctor1@example.com", availableSlots: ["Monday: 10AM - 12PM"], languagesSpoken: ["English", "Hindi"]),
    
    Doctor(name: "Dr. Kavita Mishra", specialization: "Neurologist", qualifications: "MBBS, DM", experience: 15, hospitalAffiliations: ["Fortis"], consultationFee: 800.0, phoneNumber: "9876543213", email: "doctor4@example.com", availableSlots: ["Monday: 2PM - 5PM"], languagesSpoken: ["English", "Marathi"])
]
