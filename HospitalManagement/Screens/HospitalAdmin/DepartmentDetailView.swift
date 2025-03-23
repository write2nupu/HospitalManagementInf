import SwiftUI

struct DepartmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
    let department: Department
    @State private var showAddDoctor = false
    @State private var searchText = ""
    @State private var statusFilter: StatusFilter = .all
    
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
    
    private var departmentDoctors: [Doctor] {
        // Make sure we're getting the latest doctors from the view model
        let doctors = viewModel.getDoctorsByHospital(hospitalId: department.hospital_id ?? UUID())
            .filter { $0.department_id == department.id }
        
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
                doctor.phone_number.localizedCaseInsensitiveContains(searchText) ||
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Department Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Text("Department ID")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("#\(department.id.uuidString.prefix(8))")
                                .font(.subheadline)
                                .foregroundColor(.mint)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text("Total Doctors")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(departmentDoctors.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.mint)
                        }
                    }
                    
                    if let description = department.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Consultation Fee: $\(String(format: "%.2f", department.fees))")
                        .font(.subheadline)
                        .foregroundColor(.mint)
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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
                
                // Doctors List
                VStack(spacing: 16) {
                    HStack {
                        Text("Department Doctors")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            showAddDoctor = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.mint)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    if departmentDoctors.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.mint.opacity(0.3))
                            Text(emptyStateMessage)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Add doctors to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(departmentDoctors) { doctor in
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
        .navigationTitle(department.name)
        .navigationBarTitleDisplayMode(.large)
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
    }
}

struct DoctorListCard: View {
    let doctor: Doctor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(doctor.full_name)
                    .font(.headline)
                Spacer()
                StatusBadge(isActive: doctor.is_active)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(doctor.phone_number)
                } icon: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                }
                
                Label {
                    Text(doctor.email_address)
                } icon: {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.mint)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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

