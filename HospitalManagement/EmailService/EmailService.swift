//
//  EmailService.swift
//  HospitalManagement
//
//  Created by Mariyo on 22/03/25.
//

import Foundation
import Foundation
import SwiftSMTP

class EmailService {
    static let shared = EmailService()
    
    private let smtp: SMTP
    private let senderEmail = "jashansingh2292004@gmail.com"
    // TODO: Replace with your Gmail App Password
    // To generate an App Password:
    // 1. Go to Google Account Settings
    // 2. Security > 2-Step Verification (enable if not enabled)
    // 3. Security > App Passwords
    // 4. Generate new App Password for "HMS"
    private let senderPassword = "hhiu jegk kxwh juuo" // Add your app password here
    
    private init() {
        smtp = SMTP(
            hostname: "smtp.gmail.com",
            email: senderEmail,
            password: senderPassword,
            port: 587,
            tlsMode: .requireSTARTTLS,
            authMethods: [.plain],
            timeout: 10
        )
    }
    
    func sendEmail(to recipient: String, subject: String, body: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let mail = Mail(
                from: Mail.User(email: senderEmail),
                to: [Mail.User(email: recipient)],
                subject: subject,
                text: body
            )
            
            smtp.send(mail) { error in
                if let error = error {
                    print("Failed to send email:", error)
                    continuation.resume(throwing: error)
                } else {
                    print("Email sent successfully to:", recipient)
                    continuation.resume()
                }
            }
        }
    }
    
    func sendAdminCredentials(to admin: Admin, hospitalName: String) async throws {
        let subject = "Welcome to \(hospitalName) - Your Admin Credentials"
        let body = """
        Dear \(admin.full_name),

        Welcome to the Hospital Management System. You have been assigned as an administrator for \(hospitalName).

        Your login credentials are:
        Email: \(admin.email)
        Initial Password: \(admin.initial_password)

        Please change your password upon your first login for security purposes.

        Best regards,
        Hospital Management System Team
        """
        
        try await sendEmail(to: admin.email, subject: subject, body: body)
    }
    
    func sendDoctorCredentials(to doctor: Doctor, password: String, departmentName: String) async throws {
        let subject = "Welcome - Your Doctor Account Credentials"
        let body = """
        Dear Dr. \(doctor.full_name),

        Welcome to the Hospital Management System. You have been registered as a doctor in the \(departmentName) department.

        Your login credentials are:
        Email: \(doctor.email_address)
        Initial Password: \(password)

        Please change your password upon your first login for security purposes.

        Best regards,
        Hospital Management System Team
        """
        
        try await sendEmail(to: doctor.email_address, subject: subject, body: body)
    }
}
