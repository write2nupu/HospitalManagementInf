//import SwiftUI
//
//struct InvoicesTabView: View {
//    @Binding var selectedHospitalId: String
//
//    
//    var body: some View {
//        ZStack(alignment: .top) {
//            Group {
//                if selectedHospitalId.isEmpty {
//                    NoHospitalSelectedView()
//                        .padding(.top, 50) // Add space at the top for the sticky header
//                } else {
//                    ScrollView {
//                        VStack(alignment: .leading, spacing: 20) {
//                            // Invoices Section
//                            VStack(alignment: .leading, spacing: 15) {
//                                Text("Billing Invoices")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//                                    .foregroundColor(AppConfig.fontColor)
//                                    .padding(.horizontal)
//                                
//                                // Placeholder for invoices
//
//                                InvoiceCard(
//                                    title: "Hospital Consultation",
//                                    date: Date(),
//                                    amount: 500.00,
//                                    status: .paid
//                                )
//                                
//                                InvoiceCard(
//                                    title: "Lab Tests",
//                                    date: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
//                                    amount: 1200.00,
//                                    status: .pending
//                                )
//                            }
//                        }
//                        .padding(.vertical)
//                        .padding(.top, 50) // Add space at the top for the sticky header
//                    }
//                    .background(AppConfig.backgroundColor)
//                }
//            }
//            
//            // Sticky header for Invoices tab
//            VStack(spacing: 0) {
//                Text("Invoices")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal)
//                    .padding(.top, 10)
//                    .background(Color(.systemBackground))
//                
//                Divider()
//            }
//            .background(Color(.systemBackground))
//            .zIndex(1) // Ensure header appears on top
//        }
//    }
//
//}
//
//// MARK: - Invoice Card Helper
//enum InvoiceStatus {
//    case paid
//    case pending
//    case overdue
//}
//
//struct InvoiceCard: View {
//    let title: String
//    let date: Date
//    let amount: Double
//    let status: InvoiceStatus
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "doc.text.fill")
//                .font(.system(size: 24))
//                .foregroundColor(statusColor(status))
//                .frame(width: 50, height: 50)
//                .background(statusColor(status).opacity(0.1))
//                .cornerRadius(10)
//            
//            VStack(alignment: .leading, spacing: 5) {
//                Text(title)
//                    .font(.headline)
//                    .foregroundColor(AppConfig.fontColor)
//                
//                Text(formatInvoiceDate(date))
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            VStack(alignment: .trailing, spacing: 5) {
//                Text("₹\(String(format: "%.2f", amount))")
//                    .font(.headline)
//                    .foregroundColor(AppConfig.fontColor)
//                
//                Text(statusText(status))
//                    .font(.caption)
//                    .foregroundColor(statusColor(status))
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color(.systemBackground))
//                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//        )
//        .padding(.horizontal)
//        .padding(.vertical, 5)
//    }
//    
//    private func formatInvoiceDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        return formatter.string(from: date)
//    }
//    
//    private func statusColor(_ status: InvoiceStatus) -> Color {
//        switch status {
//        case .paid: return .green
//        case .pending: return .orange
//        case .overdue: return .red
//        }
//    }
//    
//    private func statusText(_ status: InvoiceStatus) -> String {
//        switch status {
//        case .paid: return "Paid"
//        case .pending: return "Pending"
//        case .overdue: return "Overdue"
//        }
//    }
//}
//
//#Preview {
//    NavigationView {
//        InvoicesTabView(selectedHospitalId: .constant("123"))
//    }
//} 
