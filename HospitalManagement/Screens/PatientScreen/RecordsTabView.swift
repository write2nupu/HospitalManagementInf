import SwiftUI

struct RecordsTabView: View {
    @Binding var selectedHospitalId: String
    
    var body: some View {
        Group {
            if selectedHospitalId.isEmpty {
                NoHospitalSelectedView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Medical Records Section
                        VStack(alignment: .leading, spacing: 15) {
                            // Placeholder for medical records
                            RecordCategoryCard(title: "Lab Reports", iconName: "cross.case.fill", count: 0)
                            RecordCategoryCard(title: "Prescriptions", iconName: "pill.fill", count: 0)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .background(AppConfig.backgroundColor)
            }
        }
        .navigationTitle("Medical Records")
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Record Category Card
struct RecordCategoryCard: View {
    let title: String
    let iconName: String
    let count: Int
    
    var body: some View {
        NavigationLink(destination: RecordDetailView(title: title)) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(AppConfig.buttonColor)
                    .frame(width: 50, height: 50)
                    .background(AppConfig.buttonColor.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    Text("\(count) records")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(.vertical, 5)
        }
    }
}

// MARK: - Record Detail View
struct RecordDetailView: View {
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("No records available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(AppConfig.backgroundColor)
    }
}

// MARK: - No Hospital Selected View
struct NoHospitalSelectedView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(AppConfig.buttonColor.opacity(0.5))
            
            Text("No Hospital Selected")
                .font(.title3)
                .foregroundColor(AppConfig.fontColor)
            
            Text("Please select a hospital to view your information")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                selectedTab = 0
            }) {
                Text("Go to Home")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConfig.buttonColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 50)
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationView {
        RecordsTabView(selectedHospitalId: .constant(""))
    }
} 
