import SwiftUI

struct BedRequestsView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
    var body: some View {
        List {
            ForEach(0..<10) { _ in // Replace with actual bed requests data
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Bed Request #456")
                            .font(.headline)
                        Spacer()
                        Text("1h ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.mint)
                        Text("Jane Smith")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.blue)
                        Text("General Ward")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Required for:")
                            .foregroundColor(.secondary)
                        Text("3 days")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    
                    Button(action: {
                        // Handle allocation action
                    }) {
                        Text("Allocate Bed")
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
        .navigationTitle("Bed Requests")
        .navigationBarTitleDisplayMode(.inline)
    }
} 

#Preview {
    BedRequestsView()
}
