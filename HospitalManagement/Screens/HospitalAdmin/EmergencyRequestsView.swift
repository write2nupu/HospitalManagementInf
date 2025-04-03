import SwiftUI

struct EmergencyRequestsView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var emergencyRequests: [EmergencyAppointment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("hospitalId") private var hospitalIdString: String?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if emergencyRequests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cross.case")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("No Emergency Requests")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Emergency requests will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(emergencyRequests) { request in
                    EmergencyRequestCard(request: request)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Emergency Requests")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await loadEmergencyRequests()
            }
        }
        .refreshable {
            await loadEmergencyRequests()
        }
    }
    
    private func loadEmergencyRequests() async {
        guard let hospitalIdString = hospitalIdString,
              let hospitalId = UUID(uuidString: hospitalIdString) else {
            errorMessage = "Hospital ID not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            emergencyRequests = try await supabaseController.fetchEmergencyRequests(hospitalId: hospitalId)
            print("Fetched \(emergencyRequests.count) emergency requests")
        } catch {
            errorMessage = "Failed to load emergency requests: \(error.localizedDescription)"
            print("Error loading emergency requests: \(error)")
        }
        
        isLoading = false
    }
}

struct EmergencyRequestCard: View {
    let request: EmergencyAppointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Emergency Info
            HStack(alignment: .center, spacing: 12) {
                // Emergency Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emergency Request")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(request.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge9(status: request.status.rawValue)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Request Details
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(request.description)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct StatusBadge9: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "assigned":
            return .green
        default:
            return .gray
        }
    }
    
    var statusIcon: String {
        switch status.lowercased() {
        case "pending":
            return "exclamationmark.circle.fill"
        case "assigned":
            return "checkmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}

#Preview {
    EmergencyRequestsView()
}
