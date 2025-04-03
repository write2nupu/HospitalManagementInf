import SwiftUI

// Add this helper view before the HomeTabView struct
struct HospitalSelectionCard: View {
    let hospital: Hospital?
    
    var body: some View {
        VStack(spacing: 12) {
            if let hospital = hospital {
                // Selected Hospital Card View
                HStack(alignment: .center, spacing: 15) {
                    Image(systemName: "building.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppConfig.buttonColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hospital.name)
                            .font(.headline)
                            .foregroundColor(AppConfig.fontColor)
                            .fontWeight(.semibold)
                        
                        Text("\(hospital.city), \(hospital.state)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(AppConfig.buttonColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppConfig.buttonColor, lineWidth: 1)
                        )
                }
            } else {
                // No Hospital Selected View
                HStack {
                    Image(systemName: "building.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppConfig.buttonColor)
                    
                    Text("Select Hospital")
                        .font(.title3)
                        .foregroundColor(AppConfig.fontColor)
                        .fontWeight(.regular)
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor, radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

struct LatestAppointmentCard: View {
    let appointment: Appointment
    
    var body: some View {
        NavigationLink(destination: LatestAppointmentView(appointment: appointment)) {
            HStack(spacing: 15) {
                Image(systemName: appointment.type == .Emergency ? "cross.case.fill" : "calendar.badge.plus")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        appointment.type == .Emergency ? AppConfig.redColor : AppConfig.buttonColor
                    )
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(appointment.type.rawValue)
                        .font(.headline)
                        .foregroundColor(
                            appointment.type == .Emergency ? AppConfig.redColor : AppConfig.buttonColor
                        )
                    
                    Text(formattedDate(appointment.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(
                        appointment.type == .Emergency ? AppConfig.redColor : AppConfig.buttonColor
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        appointment.type == .Emergency ?
                        Color.red.opacity(0.1) : Color.mint.opacity(0.1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmergencyCard: View {
    var body: some View {
        NavigationLink(destination: EmergencyAssistanceView()) {
            HStack(spacing: 15) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Emergency Assistance")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Immediate medical help")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.red)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.red.opacity(0.1))
                    .shadow(color: Color.red.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
    }
}

struct ServicesGridView: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            NavigationLink(destination: DepartmentListView()) {
                ServiceCard(
                    icon: "calendar.badge.plus",
                    title: "Book\nAppointment"
                )
            }
            
            NavigationLink(destination: PrescriptionLabTestView()) {
                ServiceCard(
                    icon: "cross.vial.fill",
                    title: "Book\nLab Test"
                )
            }
            
            NavigationLink(destination: CurrentBedBookingView()) {
                ServiceCard(
                    icon: "bed.double.fill",
                    title: "Book\nBed"
                )
            }
        }
        .padding(.horizontal)
    }
}

struct PatientDepartmentsSection: View {
    let departments: [Department]
    let departmentDoctors: [UUID: [Doctor]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Departments")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.fontColor)
                
                Spacer()
                
                NavigationLink(destination: DepartmentListView()) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(AppConfig.buttonColor)
                }
            }
            .padding(.horizontal)
            .padding(.top, 15)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(departments.prefix(5)) { department in
                        NavigationLink(destination: DoctorListView(doctors: departmentDoctors[department.id] ?? [])) {
                            DepartmentCard(
                                department: department,
                                doctorCount: departmentDoctors[department.id]?.count ?? 0
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }
}

struct HomeTabView: View {
    @Binding var selectedHospital: Hospital?
    @Binding var departments: [Department]
    @State private var latestAppointment: Appointment?
    @State private var showPrescriptionLabTestView = false
    @State private var isLoadingAppointment = true
    @State private var departmentDoctors: [UUID: [Doctor]] = [:]
    @StateObject private var supabase = SupabaseController()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Quick Actions Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Hospital")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.fontColor)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    NavigationLink(destination: HospitalListView()) {

//                        VStack(spacing: 12) {
//                            if let hospital = selectedHospital {
//                                // Selected Hospital Card View
//                                HStack(alignment: .center, spacing: 15) {
//                                    Image(systemName: "building.fill")
//                                        .font(.system(size: 36))
//                                        .foregroundColor(AppConfig.buttonColor)
//                                    
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text(hospital.name)
//                                            .font(.headline)
//                                            .foregroundColor(AppConfig.fontColor)
//                                            .fontWeight(.semibold)
//                                        
//                                        Text("\(hospital.city), \(hospital.state)")
//                                            .font(.subheadline)
//                                            .foregroundColor(.secondary)
//                                            .lineLimit(1)
//                                    }
//                                    
//                                    Spacer()
//                                    
//                                    Text("Change")
//                                        .font(.caption)
//                                        .foregroundColor(AppConfig.buttonColor)
//                                        .padding(.horizontal, 10)
//                                        .padding(.vertical, 4)
//                                        .background(
//                                            RoundedRectangle(cornerRadius: 10)
//                                                .strokeBorder(AppConfig.buttonColor, lineWidth: 1)
//                                        )
//                                }
//                            } else {
//                                // No Hospital Selected View
//                                HStack {
//                                    Image(systemName: "building.fill")
//                                        .font(.system(size: 40))
//                                        .foregroundColor(AppConfig.buttonColor)
//                                    
//                                    Text("Select Hospital")
//                                        .font(.title3)
//                                        .foregroundColor(AppConfig.fontColor)
//                                        .fontWeight(.regular)
//                                    
//                                    Spacer()
//                                }
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(
//                            RoundedRectangle(cornerRadius: 15)
//                                .fill(AppConfig.cardColor)
//                                .shadow(color: AppConfig.shadowColor, radius: 10, x: 0, y: 5)
//                        )
//                        .padding(.horizontal)

                        HospitalSelectionCard(hospital: selectedHospital)

                    }
                }
                
                // Only show Services and Departments if a hospital is selected
                if let hospital = selectedHospital {
                    // MARK: - Latest Appointment Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Latest Appointment")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        if isLoadingAppointment {
                            ProgressView()
                                .padding()
                        } else if let appointment = latestAppointment {
                            LatestAppointmentCard(appointment: appointment)
                        }
                    }
                    .padding(.top, 10)
                    
                    // MARK: - Emergency Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Emergency")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        EmergencyCard()
                    }
                    .padding(.top, 10)
                    
                    // MARK: - Services Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Services")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        ServicesGridView()
                    }
                    
                    // MARK: - Departments Section
                    PatientDepartmentsSection(departments: departments, departmentDoctors: departmentDoctors)
                }
            }
            .padding(.vertical)
        }
        .background(AppConfig.backgroundColor)
        .task {
            await fetchLatestAppointment()
            await fetchDoctorsForDepartments()
        }
    }
    
    private func fetchLatestAppointment() async {
        guard let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId"),
              let patientId = UUID(uuidString: patientIdString) else {
            isLoadingAppointment = false
            return
        }
        
        do {
            let appointments = try await supabase.fetchAppointmentsForPatient(patientId: patientId)
            
            // Get current date without time component for accurate comparison
            let now = Calendar.current.startOfDay(for: Date())
            
            // Filter for:
            // 1. Only scheduled appointments
            // 2. Only future appointments
            // 3. Get the nearest date
            latestAppointment = appointments
                .filter { $0.status == .scheduled } // Only scheduled appointments
                .filter { $0.date >= now } // Only future appointments
                .min { $0.date < $1.date } // Get the nearest date
            
        } catch {
            print("Error fetching latest appointment:", error)
        }
        
        isLoadingAppointment = false
    }
    
    private func fetchDoctorsForDepartments() async {
        for department in departments {
            do {
                let doctors = try await supabase.getDoctorsByDepartment(departmentId: department.id)
                await MainActor.run {
                    departmentDoctors[department.id] = doctors
                }
            } catch {
                print("Error fetching doctors for department \(department.id): \(error)")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Add this helper view for consistent card styling
struct ServiceCard: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(AppConfig.buttonColor)
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(AppConfig.fontColor)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppConfig.cardColor)
                .shadow(color: AppConfig.shadowColor, radius: 10, x: 0, y: 5)
        )
    }
}

// Add this new view for latest appointment details
struct LatestAppointmentView: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with checkmark
            VStack(spacing: 15) {
                Circle()
                    .fill(Color.mint)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                    .padding(.top, 40)
                
                Text("Appointment Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 30)
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Appointment Info Card
                    VStack(spacing: 15) {
                        appointmentDetailRow(
                            icon: "calendar",
                            title: "Date",
                            value: formatDate(appointment.date)
                        )
                        
                        Divider()
                        
                        appointmentDetailRow(
                            icon: "clock",
                            title: "Time",
                            value: formatTime(appointment.date)
                        )
                        
                        Divider()
                        
                        appointmentDetailRow(
                            icon: "stethoscope",
                            title: "Type",
                            value: appointment.type.rawValue
                        )
                        
                        Divider()
                        
                        appointmentDetailRow(
                            icon: "checkmark.circle",
                            title: "Status",
                            value: appointment.status.rawValue,
                            valueColor: statusColor(appointment.status)
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func appointmentDetailRow(icon: String, title: String, value: String, valueColor: Color = .primary) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.mint)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:
            return .mint
        case .completed:
            return .blue
        case .cancelled:
            return .red
        }
    }
}

// Add this new DepartmentCard view
struct DepartmentCard: View {
    let department: Department
    let doctorCount: Int
    
    // Department-specific icons
    private func iconName(for department: String) -> String {
        let name = department.lowercased()
        switch name {
        case let n where n.contains("cardio"):
            return "heart.fill"
        case let n where n.contains("ortho"):
            return "figure.walk"
        case let n where n.contains("neuro"):
            return "brain.head.profile"
        case let n where n.contains("pediatric"):
            return "figure.2.and.child.holdinghands"
        case let n where n.contains("dental"):
            return "tooth.fill"
        case let n where n.contains("eye"):
            return "eye.fill"
        case let n where n.contains("surgery"):
            return "cross.case.fill"
        case let n where n.contains("gynec"):
            return "figure.dress.line.vertical.figure"
        case let n where n.contains("derma"):
            return "hand.raised.fill"
        case let n where n.contains("psych"):
            return "brain.fill"
        default:
            return "stethoscope"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Section: Icon and Department Name
            HStack(spacing: 10) {
                // Department Icon
                Image(systemName: iconName(for: department.name))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppConfig.buttonColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppConfig.cardColor)
                    )
                
                // Department Name
                Text(department.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Description
            if let description = department.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Bottom Section: Doctor Count
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12))
                Text("\(doctorCount) Doctors")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(AppConfig.buttonColor)
        }
        .frame(width: 200, height: 120) // Reduced size
        .padding(12) // Reduced padding
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppConfig.cardColor)
                .shadow(
                    color: Color.black.opacity(0.06),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
    }
}

