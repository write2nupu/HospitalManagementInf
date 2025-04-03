import SwiftUI

struct LeaveStatusCard: View {
    let leave: Leave
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                // Leave Icon with Background
                Circle()
                    .fill(AppConfig.buttonColor.opacity(0.1))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(AppConfig.buttonColor)
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(leave.reason)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(leave.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Status Badge
                Text(leave.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(statusColor(for: leave.status).opacity(0.1))
                    )
                    .foregroundColor(statusColor(for: leave.status))
            }
            
            Divider()
            
            // Date Range with Icons
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppConfig.buttonColor)
                    Text("From: \(formatDate(leave.startDate, format: "MMM d, yyyy"))")
                        .font(.subheadline)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppConfig.buttonColor)
                    Text("Until: \(formatDate(leave.endDate, format: "MMM d, yyyy"))")
                        .font(.subheadline)
                }
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current  // Ensure we're using the correct timezone
        formatter.locale = Locale(identifier: "en_US_POSIX")  // Use standard locale for consistent formatting
        print("Formatting date: \(date) with format: \(format), result: \(formatter.string(from: date))")
        return formatter.string(from: date)
    }
    
    private func statusColor(for status: LeaveStatus) -> Color {
        switch status {
        case .approved: return .green
        case .pending: return .orange
        case .rejected: return .red
        }
    }
}

//#Preview {
//    LeaveStatusCard(leave: Leave(id: UUID(), doctorId: UUID(), hospitalId: UUID(), type: .annualLeave, reason: "Personal vacation", startDate: Date(), endDate: Date(), status: .pending))
//}
