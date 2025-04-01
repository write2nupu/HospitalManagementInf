import Foundation

enum AppointmentShift: String, CaseIterable, Identifiable {
    case morning = "Morning Shift (9 AM - 1 PM)"
    case evening = "Evening Shift (2 PM - 7 PM)"
    
    var id: String { self.rawValue }
    
    var timeRange: (start: Date, end: Date) {
        let calendar: Calendar = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone.current
            return cal
        }()
        
        let now = calendar.startOfDay(for: Date())
        
        switch self {
        case .morning:
            let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
            let end = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now)!
            return (start, end)
        case .evening:
            let start = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now)!
            let end = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now)!
            return (start, end)
        }
    }
} 