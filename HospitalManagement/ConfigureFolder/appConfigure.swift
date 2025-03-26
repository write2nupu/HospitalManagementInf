//
//  appConfigure.swift
//  HospitalManagement
//
//  Created by Anubhav Dubey on 18/03/25.
//

import SwiftUI

// MARK: - App Configuration
struct AppConfig {
    static let backgroundColor = Color(.white) // BackGroundColor
    static let primaryColor = Color(.mint.opacity(0.2)) // PrimaryColor
    static let buttonColor = Color(.mint) // PrimaryColor
    static let fontColor = Color(.black)
    static let cardColor = Color(.white)
    static let shadowColor = Color.black.opacity(0.1) // Shadow Color
}

// MARK: - Hex Color Extension 
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1.0; g = 1.0; b = 1.0
        }
        self.init(red: r, green: g, blue: b)
    }
}
