import SwiftUI

struct PatientView: View {
    @State private var searchText: String = ""
    @StateObject private var supabase = SupabaseController()
    @State private var appointments: [Appointment] = []
    @State private var patients: [UUID: Patient] = [:]
    @State private var isLoading = true
    @State private var error: Error?
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @State private var refreshTimer: Timer?
    @State private var isViewActive = true
    @State private var loadDataTask: Task<Void, Never>?
    
    var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return Array(patients.values)
        }
        return Array(patients.values).filter { 
            $0.fullname.localizedCaseInsensitiveContains(searchText) 
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header and Search
            VStack(spacing: 8) {
                PatientSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical)
//                    .background(AppConfig.searchBar)
            }
            .background(AppConfig.backgroundColor)
            .zIndex(1)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack {
                    Text("Error loading patients")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await startLoadingData()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Scrollable Content
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    LazyVStack(spacing: 7) {
                        ForEach(filteredPatients) { patient in
                            NavigationLink(destination: PatientDetailView(patient: patient)) {
                                PatientCard(patient: patient)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                }
            }
        }
        .background(AppConfig.backgroundColor)
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            isViewActive = true
            startLoadingData()
        }
        .onDisappear {
            isViewActive = false
            cancelLoadingTask()
            stopRefreshTimer()
        }
    }
    
    private func startLoadingData() {
        cancelLoadingTask()
        loadDataTask = Task {
            await loadPatients()
            
            // Start refresh timer after initial load
            if isViewActive {
                startRefreshTimer()
            }
        }
    }
    
    private func cancelLoadingTask() {
        loadDataTask?.cancel()
        loadDataTask = nil
    }
    
    private func startRefreshTimer() {
        stopRefreshTimer()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            if isViewActive {
                startLoadingData()
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func loadPatients() async {
        guard !Task.isCancelled && isViewActive else { return }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            guard let doctorId = UUID(uuidString: currentUserId) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid doctor ID"])
            }
            
            guard !Task.isCancelled else { return }
            let fetchedAppointments = try await supabase.fetchDoctorAppointments(doctorId: doctorId)
            
            guard !Task.isCancelled && isViewActive else { return }
            
            // Update appointments on main thread
            await MainActor.run {
                appointments = fetchedAppointments
            }
            
            // Extract unique patient IDs from appointments
            let uniquePatientIds = Set(fetchedAppointments.map { $0.patientId })
            
            // Fetch patient details for each unique patient ID
            var fetchedPatients: [UUID: Patient] = [:]
            for patientId in uniquePatientIds {
                guard !Task.isCancelled else { return }
                do {
                    let patient = try await supabase.fetchPatientById(patientId: patientId)
                    fetchedPatients[patientId] = patient
                } catch {
                    print("Error fetching patient \(patientId): \(error)")
                }
            }
            
            guard !Task.isCancelled && isViewActive else { return }
            await MainActor.run {
                patients = fetchedPatients
            }
            
        } catch {
            guard !Task.isCancelled && isViewActive else { return }
            await MainActor.run {
                self.error = error
            }
        }
        
        guard !Task.isCancelled && isViewActive else { return }
        await MainActor.run {
            isLoading = false
        }
    }
}

struct PatientSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search patients...", text: $text)
                .foregroundColor(.primary)
                .font(.subheadline) // 🔹 Reduced font size
                .padding(6) // 🔹 Decreased padding
        }
        .padding(8) // 🔹 Reduced overall height
        .background(AppConfig.searchBar)
        .cornerRadius(8) // 🔹 Slightly reduced corner radius
    }
}


// 🔹 Patient Card View
struct PatientCard: View {
    let patient: Patient
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(patient.fullname)
                    .font(.headline)
                
                HStack {
                    Text("Gender: \(patient.gender)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("No: \(patient.contactno)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(AppConfig.cardColor)
        .cornerRadius(12)
        .shadow(color: AppConfig.shadowColor, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    PatientView()
}
