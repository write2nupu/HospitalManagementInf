//
//  appConfigure.swift
//  HospitalManagement
//
//  Created by Anubhav Dubey on 18/03/25.
//
import SwiftUI
import SwiftUI

struct AppConfig {
    static let backgroundColor = Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .systemGroupedBackground })
    static let primaryColor = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#98FF98")!.withAlphaComponent(0.4) : UIColor(hex: "#98FF98")!.withAlphaComponent(0.2) }) // Light Green (Mint)
    static let buttonColor = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#98FF98")! : UIColor(hex: "#3EB489")! }) // Mint Color
    static let fontColor = Color(UIColor { $0.userInterfaceStyle == .dark ? .white : .black })
    static let cardColor = Color(UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white })
    static let shadowColor = Color(UIColor { $0.userInterfaceStyle == .dark ? .clear : UIColor.black.withAlphaComponent(0.1) })
    static let searchBar = Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .systemBackground })

    // Status Colors (Pending, Approved, Rejected)
    static let pendingColor = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#B8860B")! : UIColor(hex: "#FFD700")! }) // Darker Gold
    static let approvedColor = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#228B22")! : UIColor(hex: "#CCFFCC")! }) // Dark Green
    static let rejectedColor = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#8B0000")! : UIColor(hex: "#e8a1a4")! }) // Dark Red
    static let redColor = Color(UIColor { $0.userInterfaceStyle == .dark ? .red : .red }) // Dark Red
}

// UIColor extension for Hex Support
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
