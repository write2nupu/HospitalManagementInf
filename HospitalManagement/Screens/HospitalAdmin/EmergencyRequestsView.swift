import SwiftUI

struct EmergencyRequestsView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
    var body: some View {
        List {
            ForEach(0..<10) { _ in // Replace with actual emergency requests data
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Emergency Request #123")
                            .font(.headline)
                        Spacer()
                        Text("2h ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.mint)
                        Text("John Doe")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.red)
                        Text("Cardiac Emergency")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        // Handle response action
                    }) {
                        Text("Respond")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.mint)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Emergency Requests")
    }
} 