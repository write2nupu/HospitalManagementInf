import Foundation

struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    
    var isAvailable: Bool = true
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(startTime)
        hasher.combine(endTime)
    }
    
    // Implement Equatable
    static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
        return lhs.startTime == rhs.startTime && lhs.endTime == rhs.endTime
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime))"
    }
    
    static func isValidTime(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // Convert to minutes since start of day for easier comparison
        let timeInMinutes = hour * 60 + minute
        
        // Morning shift: 9 AM to 1 PM (540 to 780 minutes)
        // Evening shift: 2 PM to 7 PM (840 to 1140 minutes)
        return (timeInMinutes >= 540 && timeInMinutes <= 780) || // 9 AM to 1 PM
               (timeInMinutes >= 840 && timeInMinutes <= 1140)   // 2 PM to 7 PM
    }
    
    static func generateTimeSlots(for date: Date) -> [TimeSlot] {
        let calendar: Calendar = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
            return cal
        }()
        
        let startOfDay = calendar.startOfDay(for: date)
        var timeSlots: [TimeSlot] = []
        
        // Morning slots: 9 AM to 1 PM
        var currentTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startOfDay)!
        let morningEnd = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: startOfDay)!
        
        while currentTime < morningEnd {
            let slotEnd = calendar.date(byAdding: .minute, value: 30, to: currentTime)!
            timeSlots.append(TimeSlot(startTime: currentTime, endTime: slotEnd))
            currentTime = slotEnd
        }
        
        // Evening slots: 2 PM to 7 PM
        currentTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: startOfDay)!
        let eveningEnd = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: startOfDay)!
        
        while currentTime < eveningEnd {
            let slotEnd = calendar.date(byAdding: .minute, value: 30, to: currentTime)!
            timeSlots.append(TimeSlot(startTime: currentTime, endTime: slotEnd))
            currentTime = slotEnd
        }
        
        return timeSlots
    }
} 
