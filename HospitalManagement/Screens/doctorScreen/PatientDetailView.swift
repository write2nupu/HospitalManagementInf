import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    @StateObject private var supabase = SupabaseController()
    @State private var appointments: [Appointment] = []
    @State private var patientDetails: PatientDetails?
    @State private var isLoading = true
    @State private var error: Error?
    @AppStorage("currentUserId") private var currentUserId: String = ""

    var body: some View {
        List {
            if isLoading {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            } else if let error = error {
                Section {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }
            } else {
                Section(header: Text("Personal Information")) {
                    InfoRowPatientList(label: "Full Name", value: patient.fullname)
                    InfoRowPatientList(label: "Gender", value: patient.gender)
                    InfoRowPatientList(label: "Date of Birth", value: formatDate(patient.dateofbirth))
                    InfoRowPatientList(label: "Blood Group", value: patientDetails?.blood_group ?? "N/A")
                }
                
                Section(header: Text("Medical History")) {
                    InfoRowPatientList(label: "Allergies", value: patientDetails?.allergies ?? "None")
                    InfoRowPatientList(label: "Existing Medical Record", value: patientDetails?.existing_medical_record ?? "None")
                    InfoRowPatientList(label: "Current Medication", value: patientDetails?.current_medication ?? "None")
                    InfoRowPatientList(label: "Past Surgeries", value: patientDetails?.past_surgeries ?? "None")
                }
                
                Section(header: Text("Contact Details")) {
                    InfoRowPatientList(label: "Contact", value: patient.contactno)
                    InfoRowPatientList(label: "Email", value: patient.email)
                    InfoRowPatientList(label: "Emergency Contact", value: patientDetails?.emergency_contact ?? patient.contactno)
                }
                
                Section(header: Text("Appointments")) {
                    if appointments.isEmpty {
                        Text("No appointments found")
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(appointments.sorted(by: { $0.date > $1.date })) { appointment in
                            NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(appointment.type.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(appointment.type == .Emergency ? .red : .mint)
                                        Spacer()
                                        Text(appointment.status.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(formatDateTime(appointment.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    // Helper function to format Date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Helper function to format Date and Time
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        print("Starting loadData for patient: \(patient.fullname)")
        print("Patient detail_id: \(String(describing: patient.detail_id))")
        
        do {
            // Create a task group to handle concurrent fetches
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Load appointments
                group.addTask {
                    guard let doctorId = UUID(uuidString: self.currentUserId) else {
                        print("Invalid doctor ID: \(self.currentUserId)")
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid doctor ID"])
                    }
                    
                    print("Fetching appointments for doctor: \(doctorId)")
                    // Fetch all appointments for this doctor
                    let allAppointments = try await self.supabase.fetchDoctorAppointments(doctorId: doctorId)
                    print("Fetched \(allAppointments.count) total appointments")
                    
                    // Filter appointments for this patient
                    await MainActor.run {
                        self.appointments = allAppointments.filter { $0.patientId == self.patient.id }
                    }
                    print("Filtered to \(self.appointments.count) appointments for this patient")
                }
                
                // Fetch patient details if detail_id exists
                if let detailId = patient.detail_id {
                    group.addTask {
                        print("Attempting to fetch patient details for detailId: \(detailId)")
                        do {
                            if let details = try await self.supabase.fetchPatientDetailsById(detailId: detailId) {
                                print("Successfully fetched patient details: \(String(describing: details))")
                                await MainActor.run {
                                    self.patientDetails = details
                                }
                            } else {
                                print("No patient details found for detail_id: \(detailId)")
                            }
                        } catch {
                            print("Error fetching patient details: \(error)")
                            if !(error is NSError) || (error as NSError).code != NSURLErrorCancelled {
                                await MainActor.run {
                                    self.error = error
                                }
                            }
                        }
                    }
                } else {
                    print("No detail_id available for patient")
                }
                
                // Wait for all tasks to complete
                try await group.waitForAll()
            }
        } catch let error as NSError {
            if error.code == NSURLErrorCancelled {
                print("Network request was cancelled - this is normal during view transitions")
            } else {
                self.error = error
                print("Error loading data: \(error)")
            }
        } catch {
            self.error = error
            print("Error loading data: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
            print("Finished loading data. patientDetails: \(String(describing: patientDetails))")
        }
    }
}

// Row View for Table
struct InfoRowPatientList: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.none)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}
