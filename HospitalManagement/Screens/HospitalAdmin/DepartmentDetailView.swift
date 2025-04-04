import SwiftUI

struct DepartmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    
    let department: Department
    @State private var showAddDoctor = false
    @State private var searchText = ""
    @State private var statusFilter: StatusFilter = .all
    @State private var doctors: [Doctor] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    enum StatusFilter {
        case all, active, inactive
        
        var title: String {
            switch self {
            case .all: return "All"
            case .active: return "Active"
            case .inactive: return "Inactive"
            }
        }
    }
    
    private var filteredDoctors: [Doctor] {
        // First apply status filter
        let statusFiltered = doctors.filter { doctor in
            switch statusFilter {
            case .all: return true
            case .active: return doctor.is_active
            case .inactive: return !doctor.is_active
            }
        }
        
        // Then apply search filter
        if searchText.isEmpty {
            return statusFiltered
        } else {
            return statusFiltered.filter { doctor in
                doctor.full_name.localizedCaseInsensitiveContains(searchText) ||
                doctor.phone_num.localizedCaseInsensitiveContains(searchText) ||
                doctor.email_address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var emptyStateMessage: String {
        if searchText.isEmpty {
            let statusText = statusFilter == .all ? "" : "\(statusFilter.title.lowercased()) "
            return "No \(statusText)doctors in this department"
        } else {
            return "No doctors found"
        }
    }
    
    private var adminName: String {
        if let hospitalId = department.hospital_id,
           let admin = viewModel.getAdminByHospital(hospitalId: hospitalId) {
            return "Hi, \(admin.full_name)"
        }
        return "Department Details"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Department Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Text("Department ID")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.fontColor.opacity(0.7))
                            Text("#\(department.id.uuidString.prefix(8))")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.buttonColor)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text("Total Doctors")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.fontColor.opacity(0.7))
                            Text("\(doctors.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppConfig.buttonColor)
                        }
                    }
                    
                    if let description = department.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(AppConfig.fontColor.opacity(0.7))
                    }
                    
                    Text("Consultation Fee: ₹\(String(format: "%.2f", department.fees))")
                        .font(.subheadline)
                        .foregroundColor(AppConfig.buttonColor)
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppConfig.cardColor)
                        .shadow(color: AppConfig.shadowColor, radius: 5)
                )
                .padding(.horizontal)
                
                // Status Filter
                Picker("Filter", selection: $statusFilter) {
                    ForEach([StatusFilter.all, .active, .inactive], id: \.title) { filter in
                        Text(filter.title)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .tint(AppConfig.buttonColor)
                
                // Doctors List
                VStack(spacing: 16) {
                    HStack {
                        Text("Department Doctors")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppConfig.fontColor)
                        Spacer()
                        Button {
                            showAddDoctor = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(AppConfig.buttonColor)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading doctors...")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.fontColor.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(AppConfig.redColor.opacity(0.3))
                            Text(error)
                                .font(.headline)
                                .foregroundColor(AppConfig.fontColor)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if filteredDoctors.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppConfig.buttonColor.opacity(0.3))
                            Text(emptyStateMessage)
                                .font(.headline)
                                .foregroundColor(AppConfig.fontColor)
                            Text("Add doctors to get started")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.fontColor.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredDoctors) { doctor in
                            NavigationLink {
                                DoctorDetailView(doctor: doctor)
                            } label: {
                                DoctorListCard(doctor: doctor)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(AppConfig.backgroundColor.ignoresSafeArea())
        .navigationTitle("Department Details")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search doctors by name, phone, or email"
        )
        .sheet(isPresented: $showAddDoctor) {
            NavigationView {
                AddDoctorView(department: department)
            }
        }
        .task {
            await loadDoctors()
        }
        .refreshable {
            await loadDoctors()
        }
    }
    
    private func loadDoctors() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedDoctors = try await supabaseController.getDoctorsByDepartment(departmentId: department.id)
            await MainActor.run {
                doctors = fetchedDoctors
                isLoading = false
            }
        } catch {
            print("Error loading doctors:", error)
            await MainActor.run {
                errorMessage = "Failed to load doctors: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct DoctorListCard: View {
    let doctor: Doctor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(doctor.full_name)
                    .font(.headline)
                    .foregroundColor(AppConfig.fontColor)
                Spacer()
                StatusBadge(isActive: doctor.is_active)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(doctor.phone_num)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                } icon: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(AppConfig.approvedColor)
                }
                
                Label {
                    Text(doctor.email_address)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                } icon: {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(AppConfig.buttonColor)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor, radius: 5)
        )
    }
}

// MARK: - Preview
struct DepartmentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DepartmentDetailView(
                department: Department(
                    id: UUID(),
                    name: "Cardiology",
                    description: "Heart and cardiovascular care",
                    hospital_id: UUID(),
                    fees: 100.0
                )
            )
            .environmentObject(HospitalManagementViewModel())
        }
    }
}

