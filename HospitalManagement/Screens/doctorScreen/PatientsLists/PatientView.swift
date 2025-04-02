import SwiftUI

struct PatientView: View {
    @State private var searchText: String = ""
    @StateObject private var supabase = SupabaseController()
    @State private var appointments: [Appointment] = []
    @State private var patients: [UUID: Patient] = [:]
    @State private var isLoading = true
    @State private var error: Error?
    @AppStorage("currentUserId") private var currentUserId: String = ""
    
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
                    .padding(.bottom, 3)
            }
            .background(Color.white)
            .shadow(color: AppConfig.shadowColor, radius: 2, x: 0, y: 2)
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
                            await loadPatients()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Scrollable Content
                ScrollView {
                    LazyVStack(spacing: 15) {
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
        .background(Color(.systemGray6).opacity(0.2))
        .ignoresSafeArea(.all, edges: .bottom)
        .task {
            await loadPatients()
        }
    }
    
    private func loadPatients() async {
        isLoading = true
        error = nil
        
        do {
            guard let doctorId = UUID(uuidString: currentUserId) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid doctor ID"])
            }
            
            // Fetch appointments for the doctor
            appointments = try await supabase.fetchDoctorAppointments(doctorId: doctorId)
            
            // Extract unique patient IDs from appointments
            let uniquePatientIds = Set(appointments.map { $0.patientId })
            
            // Fetch patient details for each unique patient ID
            var fetchedPatients: [UUID: Patient] = [:]
            for patientId in uniquePatientIds {
                do {
                    let patient = try await supabase.fetchPatientById(patientId: patientId)
                    fetchedPatients[patientId] = patient
                } catch {
                    print("Error fetching patient \(patientId): \(error)")
                }
            }
            
            patients = fetchedPatients
        } catch {
            self.error = error
        }
        
        isLoading = false
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
        .background(Color(.systemGray6))
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
        .background(AppConfig.backgroundColor)
        .cornerRadius(12)
        .shadow(color: AppConfig.shadowColor, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    PatientView()
}
