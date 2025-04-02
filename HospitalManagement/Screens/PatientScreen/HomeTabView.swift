import SwiftUI

struct HomeTabView: View {
    @Binding var selectedHospital: Hospital?
    @Binding var departments: [Department]
    
    var body: some View {
        ScrollView {
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
                        VStack(spacing: 12) {
                            if let hospital = selectedHospital {
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
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Only show Services and Departments if a hospital is selected
                if let hospital = selectedHospital {
                    // MARK: - Latest Appointment Section
                    if let savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]], !savedAppointments.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Latest Appointment")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppConfig.fontColor)
                                .padding(.horizontal)
                            
                            // Get the most recent appointment
                            let latestAppointment = savedAppointments.max { 
                                ($0["timestamp"] as? Date) ?? Date.distantPast < 
                                    ($1["timestamp"] as? Date) ?? Date.distantPast 
                            }
                            
                            if let appointment = latestAppointment {
                                NavigationLink(destination: AppointmentDetailsView(appointmentDetails: appointment)) {
                                    HStack(spacing: 15) {
                                        Image(systemName: appointment["appointmentType"] as? String == "Emergency" ? "cross.case.fill" : "calendar.badge.plus")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(
                                                appointment["appointmentType"] as? String == "Emergency" ? Color.red : Color.mint
                                            )
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(appointment["doctorName"] as? String ?? "Appointment")
                                                .font(.headline)
                                                .foregroundColor(
                                                    (appointment["appointmentType"] as? String) == "Emergency" ? 
                                                        .red : .mint
                                                )
                                            
                                            Text("Immediate medical help")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(
                                                (appointment["appointmentType"] as? String) == "Emergency" ? 
                                                    .red : .mint
                                            )
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(
                                                (appointment["appointmentType"] as? String) == "Emergency" ? 
                                                Color.red.opacity(0.1) : Color.mint.opacity(0.1)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    
                    // MARK: - Emergency Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Emergency")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
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
                    .padding(.top, 10)
                    
                    // MARK: - Services Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Services")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                            .padding(.horizontal)
                        
                        HStack(spacing: 15) {
                            // Book Appointment Card
                            NavigationLink(destination: DepartmentListView()) {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppConfig.buttonColor)
                                    
                                    Text("Book\nAppointment")
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(AppConfig.fontColor)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                            }
                            
                            // Book Bed Card
                            NavigationLink(destination: CurrentBedBookingView()) {
                                VStack(spacing: 12) {
                                    Image(systemName: "bed.double.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppConfig.buttonColor)
                                    
                                    Text("Book\nBed")
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(AppConfig.fontColor)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Departments Section
                    HStack {
                        Text("Departments")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConfig.fontColor)
                        
                        Spacer()
                        
                        NavigationLink(destination: DepartmentListView()) {
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.buttonColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(departments.prefix(5)) { department in
                                NavigationLink(destination: DoctorListView(doctors: [])) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(department.name)
                                            .font(.headline)
                                            .foregroundColor(.mint)
                                            .lineLimit(1)
                                        
                                        if let description = department.description {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .lineLimit(2)
                                        }
                                    }
                                    .frame(width: 150, height: 100)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                                   // .isNavigationBarHidden
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(AppConfig.backgroundColor)
    }
}
