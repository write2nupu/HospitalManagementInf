import SwiftUI

struct EmergencyRequestsView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var emergencyRequests: [EmergencyAppointment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("hospitalId") private var hospitalIdString: String?
    @State private var selectedFilter = 0 // 0 for Scheduled, 1 for Completed
    
    var filteredRequests: [EmergencyAppointment] {
        switch selectedFilter {
        case 0:
            return emergencyRequests.filter { $0.status.rawValue == "Pending" }
        case 1:
            return emergencyRequests.filter { $0.status.rawValue == "Completed" }
        default:
            return []
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("Filter", selection: $selectedFilter) {
                Text("Scheduled").tag(0)
                Text("Completed").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
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
                } else if filteredRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cross.case")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text(selectedFilter == 0 ? "No Scheduled Requests" : "No Completed Requests")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(selectedFilter == 0 ? "Scheduled emergency requests will appear here" : "Completed emergency requests will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredRequests) { request in
                        ZStack {
                            NavigationLink(destination: EmergencyRequestDetailView(request: request)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            EmergencyRequestCard(request: request)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
        }
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

struct EmergencyRequestDetailView: View {
    let request: EmergencyAppointment
    @StateObject private var supabaseController = SupabaseController()
    @State private var emergencyDoctors: [Doctor] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDoctor: Doctor?
    @State private var showingDoctorPicker = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hospitalId") private var hospitalIdString: String?
    
    private var canAssignDoctor: Bool {
        request.status.rawValue != "Completed" && request.status.rawValue != "Cancelled"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Emergency Status Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("Emergency Request")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        StatusBadge9(status: request.status.rawValue)
                    }
                    
                    Text(request.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                
                // Doctor Assignment Section
                if canAssignDoctor {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Assign Doctor")
                            .font(.headline)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        } else if emergencyDoctors.isEmpty {
                            Text("No emergency doctors available")
                                .foregroundColor(.secondary)
                        } else {
                            Button(action: {
                                showingDoctorPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text(selectedDoctor == nil ? "Select Doctor" : "Change Doctor")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            if let doctor = selectedDoctor {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Selected Doctor:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(doctor.full_name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(doctor.qualifications)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        Task {
                                            await assignDoctor(doctor)
                                        }
                                    }) {
                                        Text("Confirm Assignment")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Emergency Details")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                await loadEmergencyDoctors()
            }
        }
        .sheet(isPresented: $showingDoctorPicker) {
            DoctorPickerView(doctors: emergencyDoctors, selectedDoctor: $selectedDoctor)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Doctor has been successfully assigned to the emergency case.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred while assigning the doctor.")
        }
    }
    
    private func loadEmergencyDoctors() async {
        guard let hospitalIdString = hospitalIdString,
              let hospitalId = UUID(uuidString: hospitalIdString) else {
            errorMessage = "Hospital ID not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let department = try await supabaseController.getEmergencyDepartment(hospitalId: hospitalId)
            emergencyDoctors = try await supabaseController.getEmergencyDoctors(departmentId: department.id)
            print("Fetched \(emergencyDoctors.count) emergency doctors")
        } catch {
            errorMessage = "Failed to load emergency doctors: \(error.localizedDescription)"
            print("Error loading emergency doctors: \(error)")
        }
        
        isLoading = false
    }
    
    private func assignDoctor(_ doctor: Doctor) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseController.assignEmergencyDoctor(
                emergencyAppointment: request,
                doctorId: doctor.id
            )
            showingSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
        
        isLoading = false
    }
}

struct DoctorPickerView: View {
    let doctors: [Doctor]
    @Binding var selectedDoctor: Doctor?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(doctors) { doctor in
                Button(action: {
                    selectedDoctor = doctor
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doctor.full_name)
                                .font(.headline)
                            Text(doctor.qualifications)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedDoctor?.id == doctor.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EmergencyRequestCard: View {
    let request: EmergencyAppointment
    
    var body: some View {
        HStack {
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
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
                .padding(.leading, 8)
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
        switch status {
        case "Pending":
            return .orange
        case "Completed":
            return .green
        case "Cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    var statusIcon: String {
        switch status {
        case "Pending":
            return "exclamationmark.circle.fill"
        case "Completed":
            return "checkmark.circle.fill"
        case "Cancelled":
            return "xmark.circle.fill"
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
