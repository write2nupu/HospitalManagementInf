import Foundation

struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    
    var isAvailable: Bool = true
    
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
            let slotEnd = calendar.date(byAdding: .minute, value: 20, to: currentTime)!
            timeSlots.append(TimeSlot(startTime: currentTime, endTime: slotEnd))
            currentTime = slotEnd
        }
        
        // Evening slots: 2 PM to 7 PM
        currentTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: startOfDay)!
        let eveningEnd = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: startOfDay)!
        
        while currentTime < eveningEnd {
            let slotEnd = calendar.date(byAdding: .minute, value: 20, to: currentTime)!
            timeSlots.append(TimeSlot(startTime: currentTime, endTime: slotEnd))
            currentTime = slotEnd
        }
        
        return timeSlots
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
} 
