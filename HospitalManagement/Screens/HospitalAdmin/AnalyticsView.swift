// AnalyticsView.swift
// HospitalManagement
//
// Created for hospital admin analytics dashboard

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @StateObject private var supabaseController = SupabaseController()
    
    // Data for analytics
    @State private var totalPatients: Int = 0
    @State private var totalDoctors: Int = 0
    @State private var totalDepartments: Int = 0
    @State private var totalAppointments: Int = 0
    @State private var completedAppointments: Int = 0
    @State private var pendingAppointments: Int = 0
    @State private var cancelledAppointments: Int = 0
    
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var hospitalId: UUID? = nil
    
    // Monthly appointment data
    @State private var monthlyAppointments: [MonthlyData] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with refresh button
                HStack {
                    Text("Hospital Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            isLoading = true
                            await loadData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.mint)
                    }
                }
                .padding(.horizontal)
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Loading analytics data...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Could not load analytics")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                isLoading = true
                                await loadData()
                            }
                        }
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    // Summary Cards in a grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                    ], spacing: 16) {
                        AnalyticCard(
                            title: "Patients",
                            value: totalPatients,
                            icon: "person.crop.circle.fill",
                            color: .blue
                        )
                        
                        AnalyticCard(
                            title: "Doctors",
                            value: totalDoctors,
                            icon: "stethoscope",
                            color: .mint
                        )
                        
                        AnalyticCard(
                            title: "Departments",
                            value: totalDepartments,
                            icon: "building.2.fill",
                            color: .indigo
                        )
                        
                        AnalyticCard(
                            title: "Appointments",
                            value: totalAppointments,
                            icon: "calendar.badge.clock",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Appointments Distribution Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appointment Status")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.leading)
                        
                        ZStack {
                            if totalAppointments == 0 {
                                Text("No appointment data available")
                                    .foregroundColor(.secondary)
                                    .frame(height: 240)
                            } else {
                                PieChartView(
                                    segments: [
                                        PieSegment(value: Double(completedAppointments), color: .green, title: "Completed"),
                                        PieSegment(value: Double(pendingAppointments), color: .blue, title: "Scheduled"),
                                        PieSegment(value: Double(cancelledAppointments), color: .red, title: "Cancelled")
                                    ]
                                )
                                .frame(height: 240)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                    
                    // Monthly Trends
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Monthly Trends")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.leading)
                        
                        ZStack {
                            if monthlyAppointments.isEmpty {
                                Text("No monthly data available")
                                    .foregroundColor(.secondary)
                                    .frame(height: 240)
                            } else {
                                Chart {
                                    ForEach(monthlyAppointments) { item in
                                        BarMark(
                                            x: .value("Month", item.month),
                                            y: .value("Count", item.count)
                                        )
                                        .foregroundStyle(Color.mint.gradient)
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                                .frame(height: 240)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        // Reset error
        errorMessage = nil
        
        do {
            // 1. Get the hospital ID of the logged-in admin from UserDefaults
            if let hospitalIdString = UserDefaults.standard.string(forKey: "hospitalId"),
               let fetchedHospitalId = UUID(uuidString: hospitalIdString) {
                
                hospitalId = fetchedHospitalId
                
                // 2. Load departments
                let departments: [Department] = try await supabaseController.client
                    .from("Department")
                    .select("*")
                    .eq("hospital_id", value: fetchedHospitalId.uuidString)
                    .execute()
                    .value
                
                totalDepartments = departments.count
                
                // 3. Load doctors
                let doctors: [Doctor] = try await supabaseController.client
                    .from("Doctor")
                    .select("*")
                    .eq("hospital_id", value: fetchedHospitalId.uuidString)
                    .execute()
                    .value
                
                totalDoctors = doctors.count
                
                // 4. Load patients (count patients with appointments at this hospital)
                // First get all doctor IDs for this hospital
                let doctorIds = doctors.map { $0.id.uuidString }
                
                if !doctorIds.isEmpty {
                    // Get all appointments for these doctors
                    let appointments: [Appointment] = try await supabaseController.client
                        .from("Appointment")
                        .select("*")
                        .in("doctorId", values: doctorIds)
                        .execute()
                        .value
                    
                    // Get unique patient IDs from appointments
                    let uniquePatientIds = Set(appointments.map { $0.patientId })
                    totalPatients = uniquePatientIds.count
                    
                    // Calculate appointment stats
                    totalAppointments = appointments.count
                    completedAppointments = appointments.filter { $0.status == .completed }.count
                    pendingAppointments = appointments.filter { $0.status == .scheduled }.count
                    cancelledAppointments = appointments.filter { $0.status == .cancelled }.count
                    
                    // Calculate monthly data
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMMM"
                    
                    // Group appointments by month and count them
                    let calendar = Calendar.current
                    var monthlyData: [String: Int] = [:]
                    
                    for appointment in appointments {
                        let month = calendar.component(.month, from: appointment.date)
                        let monthName = dateFormatter.monthSymbols[month - 1]
                        monthlyData[monthName, default: 0] += 1
                    }
                    
                    // Transform dictionary to array and sort by month
                    let monthOrder = ["January", "February", "March", "April", "May", "June",
                                     "July", "August", "September", "October", "November", "December"]
                    
                    monthlyAppointments = monthOrder
                        .filter { monthlyData.keys.contains($0) }
                        .map { MonthlyData(month: $0, count: monthlyData[$0] ?? 0) }
                }
                
                // Completed loading
                await MainActor.run {
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Hospital ID not found. Please make sure you're logged in as an admin."
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load data: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// Data models for charts
struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let count: Int
}

struct PieSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
    let title: String
}

// Custom Pie Chart View
struct PieChartView: View {
    var segments: [PieSegment]
    
    private var total: Double {
        segments.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let radius = min(geometry.size.width, geometry.size.height) / 2.5
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Draw pie segments
                ForEach(segments.indices, id: \.self) { index in
                    let startAngle = self.startAngle(at: index)
                    let endAngle = self.endAngle(at: index)
                    
                    Path { path in
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                        path.closeSubpath()
                    }
                    .fill(segments[index].color)
                }
            }
            
            // Legend
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    ForEach(segments) { segment in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(segment.color)
                                .frame(width: 10, height: 10)
                            
                            Text(segment.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if total > 0 {
                                Text("\(Int((segment.value / total) * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    private func startAngle(at index: Int) -> Angle {
        let precedingTotal = segments.prefix(index).reduce(0) { $0 + $1.value }
        return .degrees(precedingTotal / total * 360 - 90)
    }
    
    private func endAngle(at index: Int) -> Angle {
        let precedingTotal = segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return .degrees(precedingTotal / total * 360 - 90)
    }
}

// Analytics Card component
struct AnalyticCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(value)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .padding(12)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    let mockViewModel = HospitalManagementViewModel()
    return AnalyticsView()
        .environmentObject(mockViewModel)
}
