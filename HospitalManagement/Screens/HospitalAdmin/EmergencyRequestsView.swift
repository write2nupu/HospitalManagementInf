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
                        .foregroundColor(AppConfig.redColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else if filteredRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cross.case")
                            .font(.system(size: 50))
                            .foregroundColor(AppConfig.redColor)
                        Text(selectedFilter == 0 ? "No Scheduled Requests" : "No Completed Requests")
                            .font(.headline)
                            .foregroundColor(AppConfig.fontColor)
                        Text(selectedFilter == 0 ? "Scheduled emergency requests will appear here" : "Completed emergency requests will appear here")
                            .font(.subheadline)
                            .foregroundColor(AppConfig.fontColor.opacity(0.7))
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
        .background(AppConfig.backgroundColor)
        .navigationTitle("Emergency Requests")
        .navigationBarTitleDisplayMode(.inline)
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
                            .foregroundColor(AppConfig.redColor)
                        Text("Emergency Request")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                        Spacer()
                        StatusBadge9(status: request.status.rawValue)
                    }
                    
                    Text(request.description)
                        .font(.body)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppConfig.cardColor)
                )
                
                // Doctor Assignment Section
                if canAssignDoctor {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Assign Doctor")
                            .font(.headline)
                            .foregroundColor(AppConfig.fontColor)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(AppConfig.redColor)
                                .font(.subheadline)
                        } else if emergencyDoctors.isEmpty {
                            Text("No emergency doctors available")
                                .foregroundColor(AppConfig.fontColor.opacity(0.7))
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
                                .background(AppConfig.buttonColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            if let doctor = selectedDoctor {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Selected Doctor:")
                                        .font(.subheadline)
                                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                                    Text(doctor.full_name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppConfig.fontColor)
                                    Text(doctor.qualifications)
                                        .font(.caption)
                                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                                    
                                    Button(action: {
                                        Task {
                                            await assignDoctor(doctor)
                                        }
                                    }) {
                                        Text("Confirm Assignment")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(AppConfig.approvedColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppConfig.cardColor)
                                )
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppConfig.cardColor)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Emergency Details")
        .background(AppConfig.backgroundColor)
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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cross.case.fill")
                    .font(.title2)
                    .foregroundColor(AppConfig.redColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emergency Request")
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                   
                }
                
                Spacer()
                
                StatusBadge9(status: request.status.rawValue)
            }
            
            // Description
            Text(request.description)
                .font(.body)
                .foregroundColor(AppConfig.fontColor)
                .lineLimit(2)
            
            // Patient Info
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Patient")
                        .font(.subheadline)
                        .foregroundColor(AppConfig.fontColor.opacity(0.7))
                    
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppConfig.fontColor.opacity(0.5))
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor, radius: 5)
        )
    }
}

struct StatusBadge9: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "pending":
            return AppConfig.pendingColor
        case "completed":
            return AppConfig.approvedColor
        case "cancelled":
            return AppConfig.rejectedColor
        default:
            return AppConfig.buttonColor
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
}

#Preview {
    EmergencyRequestsView()
} 
