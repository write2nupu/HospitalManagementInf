import SwiftUI

struct DepartmentDetailView: View {
    let department: Department
    @StateObject private var supabaseController = SupabaseController()
    @State private var doctors: [Doctor] = []
    @State private var showAddDoctor = false
    @State private var searchText = ""
    @State private var statusFilter: StatusFilter = .all
    @Environment(\.dismiss) private var dismiss
    
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
    
    var filteredDoctors: [Doctor] {
        // First apply status filter
        let statusFiltered = doctors.filter { doctor in
            switch statusFilter {
            case .all: return true
            case .active: return doctor.isActive
            case .inactive: return !doctor.isActive
            }
        }
        
        // Then apply search filter
        if searchText.isEmpty {
            return statusFiltered
        } else {
            return statusFiltered.filter { doctor in
                doctor.fullName.localizedCaseInsensitiveContains(searchText) ||
                doctor.phoneNumber.localizedCaseInsensitiveContains(searchText) ||
                doctor.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var emptyStateMessage: String {
        if searchText.isEmpty {
            let statusText = statusFilter == .all ? "" : "\(statusFilter.title.lowercased()) "
            return "No \(statusText)doctors in this department"
        } else {
            return "No doctors found"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add Doctors Header
                HStack {
                    Text("Add Doctors")
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
                
                // Status Filter
                Picker("Filter", selection: $statusFilter) {
                    ForEach([StatusFilter.all, .active, .inactive], id: \.title) { filter in
                        Text(filter.title)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Department Doctors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Department Doctors")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    if filteredDoctors.isEmpty {
                        VStack {
                            Text(emptyStateMessage)
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.top, 20)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredDoctors) { doctor in
                                NavigationLink {
                                    DoctorDetailView(doctor: doctor)
                                } label: {
                                    DoctorRowView(doctor: doctor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
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
            NavigationStack {
                AddDoctorView(department: department)
            }
        }
        .task {
            if let hospitalId = getCurrentHospitalId() {
                doctors = await supabaseController.getDoctorsByHospital(hospitalId: hospitalId)
                doctors = doctors.filter { $0.departmentId == department.id }
            }
        }
    }
    
    // Helper function to get current hospital ID (implement based on your auth system)
    private func getCurrentHospitalId() -> UUID? {
        // Implement this based on your authentication system
        // For example, get it from UserDefaults or your auth state
        return nil // Replace with actual implementation
    }
}

struct DoctorRowView: View {
    let doctor: Doctor
    @StateObject private var supabaseController = SupabaseController()
    @State private var showStatusConfirmation = false
    @State private var showStatusChangeAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                // Top row with name and status
                HStack {
                    Text(doctor.fullName)
                        .font(.headline)
                    Spacer()
                    StatusBadge1(isActive: doctor.isActive)
                }
                
                // Contact Info
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(doctor.phoneNumber)
                    } icon: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button {
                showStatusConfirmation = true
            } label: {
                Label(doctor.isActive ? "Deactivate" : "Activate",
                      systemImage: doctor.isActive ? "person.fill.xmark" : "person.fill.checkmark")
            }
            .tint(doctor.isActive ? .red : .green)
        }
        .alert(doctor.isActive ? "Confirm Deactivation" : "Confirm Activation", 
               isPresented: $showStatusConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(doctor.isActive ? "Deactivate" : "Activate", 
                  role: doctor.isActive ? .destructive : .none) {
                Task {
                    await toggleDoctorStatus()
                }
            }
        } message: {
            Text(doctor.isActive ? 
                "Are you sure you want to deactivate Dr. \(doctor.fullName)?" :
                "Do you want to activate Dr. \(doctor.fullName)?")
        }
        .alert("Status Updated", isPresented: $showStatusChangeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(doctor.fullName) has been \(doctor.isActive ? "deactivated" : "activated")")
        }
    }
    
    private func toggleDoctorStatus() async {
        var updatedDoctor = doctor
        updatedDoctor.isActive.toggle()
        
        do {
            try await supabaseController.client
                .from("Doctors")
                .update(updatedDoctor)
                .eq("id", value: updatedDoctor.id)
                .execute()
            
            showStatusChangeAlert = true
        } catch {
            print("Error updating doctor status: \(error)")
        }
    }
}

