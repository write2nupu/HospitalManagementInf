//import SwiftUI
//
//struct RecordsTabView: View {
//    @Binding var selectedHospitalId: String
//    @StateObject private var supabase = SupabaseController()
//    @State private var prescriptions: [PrescriptionData] = []
//    @State private var isLoading = false
//    @State private var doctorNames: [UUID: String] = [:] // To store doctor names
//    
//    var body: some View {
//        ZStack(alignment: .top) {
//            Group {
//                if selectedHospitalId.isEmpty {
//                    NoHospitalSelectedView()
//                        .padding(.top, 50)
//                } else {
//                    ScrollView {
//                        VStack(spacing: 20) {
//                            VStack(alignment: .leading, spacing: 15) {
//                                Text("")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//                                    .foregroundColor(AppConfig.fontColor)
//                                    .padding(.horizontal)
//                                
//                                // Lab Reports Card
//                                RecordCategoryCard<EmptyView>(
//                                    title: "Lab Reports",
//                                    iconName: "cross.case.fill",
//                                    count: 0,
//                                    destination: EmptyView()
//                                )
//                                
//                                // Prescriptions Card
//                                RecordCategoryCard<PrescriptionListView>(
//                                    title: "Prescriptions",
//                                    iconName: "pill.fill",
//                                    count: prescriptions.count,
//                                    destination: PrescriptionListView(prescriptions: prescriptions, doctorNames: doctorNames)
//                                )
//                            }
//                            .padding(.horizontal)
//                        }
//                        .padding(.vertical)
//                        .padding(.top, 50)
//                        //=======
//                        //        Group {
//                        //            if selectedHospitalId.isEmpty {
//                        //                NoHospitalSelectedView()
//                        //            } else {
//                        //                ScrollView {
//                        //                    VStack(spacing: 20) {
//                        //                        // Medical Records Section
//                        //                        VStack(alignment: .leading, spacing: 15) {
//                        //                            // Placeholder for medical records
//                        //                            RecordCategoryCard(title: "Lab Reports", iconName: "cross.case.fill", count: 0)
//                        //                            RecordCategoryCard(title: "Prescriptions", iconName: "pill.fill", count: 0)
//                        //                        }
//                        //                        .padding(.horizontal)
//                        //>>>>>>> main
//                        //                    }
//                        //                    .padding(.vertical)
//                        //                }
//                        .background(AppConfig.backgroundColor)
//                    }
//                }
//                // Sticky header
//                VStack(spacing: 0) {
//                    Text("Medical Records")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.horizontal)
//                        .padding(.top, 10)
//                        .background(Color(.systemBackground))
//                    
//                    Divider()
//                }
//                .background(Color(.systemBackground))
//                .zIndex(1)
//            }
//            .onAppear {
//                fetchPrescriptions()
//            }
//        }
//        
//        private func fetchPrescriptions() {
//            isLoading = true
//            print("🔍 Starting prescription fetch...")
//            
//            Task {
//                print("📱 Checking for patient ID in UserDefaults...")
//                if let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId") {
//                    print("✅ Found patient ID: \(patientIdString)")
//                    
//                    if let patientId = UUID(uuidString: patientIdString) {
//                        print("✅ Valid UUID format for patient ID")
//                        do {
//                            print("🔄 Fetching prescriptions from Supabase...")
//                            let fetchedPrescriptions: [PrescriptionData] = try await supabase.client
//                                .from("PrescriptionData")
//                                .select()
//                                .eq("patientId", value: patientId.uuidString)
//                                .execute()
//                                .value
//                            
//                            print("📊 Fetched prescriptions count: \(fetchedPrescriptions.count)")
//                            print("📝 Prescription data: \(fetchedPrescriptions)")
//                            
//                            print("👨‍⚕️ Fetching doctor names...")
//                            var doctorNamesDict: [UUID: String] = [:]
//                            for prescription in fetchedPrescriptions {
//                                print("🔍 Fetching doctor info for ID: \(prescription.doctorId)")
//                                if let doctor = try? await supabase.fetchDoctorById(doctorId: prescription.doctorId) {
//                                    doctorNamesDict[prescription.doctorId] = doctor.full_name
//                                    print("✅ Found doctor: \(doctor.full_name)")
//                                } else {
//                                    print("⚠️ Could not find doctor for ID: \(prescription.doctorId)")
//                                }
//                            }
//                            
//                            await MainActor.run {
//                                print("🔄 Updating UI with fetched data...")
//                                self.prescriptions = fetchedPrescriptions
//                                self.doctorNames = doctorNamesDict
//                                self.isLoading = false
//                                print("✅ UI update complete. Prescriptions count: \(self.prescriptions.count)")
//                            }
//                        } catch {
//                            print("❌ Error fetching prescriptions: \(error)")
//                            print("🔍 Detailed error: \(String(describing: error))")
//                            await MainActor.run {
//                                self.isLoading = false
//                            }
//                        }
//                    } else {
//                        print("❌ Invalid UUID format for patient ID: \(patientIdString)")
//                        await MainActor.run {
//                            self.isLoading = false
//                        }
//                    }
//                } else {
//                    print("❌ No patient ID found in UserDefaults")
//                    await MainActor.run {
//                        self.isLoading = false
//                    }
//                }
//                
//            }
//            .navigationTitle("Medical Records")
//            .navigationBarBackButtonHidden(true)
//        }
//    }
//    
//    struct RecordCategoryCard<D: View>: View {
//        let title: String
//        let iconName: String
//        let count: Int
//        let destination: D
//        
//        var body: some View {
//            NavigationLink(destination: destination) {
//                HStack {
//                    Image(systemName: iconName)
//                        .font(.system(size: 24))
//                        .foregroundColor(.blue)
//                        .frame(width: 50, height: 50)
//                        .background(Color.blue.opacity(0.1))
//                        .cornerRadius(10)
//                    
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text(title)
//                            .font(.headline)
//                            .foregroundColor(AppConfig.fontColor)
//                        
//                        Text("\(count) records")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    Spacer()
//                    
//                    Image(systemName: "chevron.right")
//                        .foregroundColor(.secondary)
//                }
//                .padding()
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(.systemBackground))
//                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                )
//                .padding(.vertical, 5)
//            }
//        }
//    }
//    
//    // MARK: - Record Detail View
//    struct RecordDetailView: View {
//        let title: String
//        
//        var body: some View {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    Text(title)
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .padding(.horizontal)
//                    
//                    Text("No records available")
//                        .font(.body)
//                        .foregroundColor(.secondary)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding()
//                }
//                .padding(.vertical)
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .background(AppConfig.backgroundColor)
//        }
//    }
//    
//    // MARK: - No Hospital Selected View
//    struct NoHospitalSelectedView: View {
//        @State private var selectedTab = 0
//        
//        var body: some View {
//            VStack(spacing: 20) {
//                Image(systemName: "building.2.crop.circle")
//                    .font(.system(size: 60))
//                    .foregroundColor(.blue.opacity(0.5))
//                
//                Text("No Hospital Selected")
//                    .font(.title3)
//                
//                Text("Please select a hospital to view records")
//                    .font(.body)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//                
//                Button(action: {
//                    selectedTab = 0
//                }) {
//                    Text("Go to Home")
//                        .fontWeight(.medium)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(AppConfig.buttonColor)
//                        .cornerRadius(10)
//                }
//                .padding(.horizontal, 50)
//                .padding(.top, 10)
//            }
//            .padding()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//    }
//    
//    #Preview {
//        NavigationView {
//            RecordsTabView(selectedHospitalId: .constant(""))
//        }
//    }
//    
//    extension PrescriptionData {
//        var formattedLabTests: [String] {
//            guard let tests = labTests else { return [] }
//            
//            // If tests is already an array, return it
//            if tests is [String] {
//                return tests
//            }
//            
//            // If tests is a string, split it
//            if let testString = tests as? String {
//                return testString.split(separator: ",")
//                    .map { String($0.trimmingCharacters(in: .whitespaces)) }
//            }
//            
//            return []
//        }
//    }
//}
import SwiftUI

struct RecordsTabView: View {
    @Binding var selectedHospitalId: String
    @StateObject private var supabase = SupabaseController()
    @State private var prescriptions: [PrescriptionData] = []
    @State private var isLoading = false
    @State private var doctorNames: [UUID: String] = [:] // To store doctor names
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if selectedHospitalId.isEmpty {
                    NoHospitalSelectedView()
                        .padding(.top, 50)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppConfig.fontColor)
                                    .padding(.horizontal)
                                
                                // Lab Reports Card
                                RecordCategoryCard<EmptyView>(
                                    title: "Lab Reports",
                                    iconName: "cross.case.fill",
                                    count: 0,
                                    destination: EmptyView()
                                )
                                
                                // Prescriptions Card
                                RecordCategoryCard<PrescriptionListView>(
                                    title: "Prescriptions",
                                    iconName: "pill.fill",
                                    count: prescriptions.count,
                                    destination: PrescriptionListView(prescriptions: prescriptions, doctorNames: doctorNames)
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .padding(.top, 50)
                    }
                    .background(AppConfig.backgroundColor)
                }
            }
            
            // Sticky header
            VStack(spacing: 0) {
                Text("Medical Records")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color(.systemBackground))
                
                Divider()
            }
            .background(Color(.systemBackground))
            .zIndex(1)
        }
        .onAppear {
            fetchPrescriptions()
        }
    }
    
    private func fetchPrescriptions() {
        isLoading = true
        print("🔍 Starting prescription fetch...")
        
        Task {
            print("📱 Checking for patient ID in UserDefaults...")
            if let patientIdString = UserDefaults.standard.string(forKey: "currentPatientId") {
                print("✅ Found patient ID: \(patientIdString)")
                
                if let patientId = UUID(uuidString: patientIdString) {
                    print("✅ Valid UUID format for patient ID")
                    do {
                        print("🔄 Fetching prescriptions from Supabase...")
                        let fetchedPrescriptions: [PrescriptionData] = try await supabase.client
                            .from("PrescriptionData")
                            .select()
                            .eq("patientId", value: patientId.uuidString)
                            .execute()
                            .value
                        
                        print("📊 Fetched prescriptions count: \(fetchedPrescriptions.count)")
                        print("📝 Prescription data: \(fetchedPrescriptions)")
                        
                        print("👨‍⚕️ Fetching doctor names...")
                        var doctorNamesDict: [UUID: String] = [:]
                        for prescription in fetchedPrescriptions {
                            print("🔍 Fetching doctor info for ID: \(prescription.doctorId)")
                            if let doctor = try? await supabase.fetchDoctorById(doctorId: prescription.doctorId) {
                                doctorNamesDict[prescription.doctorId] = doctor.full_name
                                print("✅ Found doctor: \(doctor.full_name)")
                            } else {
                                print("⚠️ Could not find doctor for ID: \(prescription.doctorId)")
                            }
                        }
                        
                        await MainActor.run {
                            print("🔄 Updating UI with fetched data...")
                            self.prescriptions = fetchedPrescriptions
                            self.doctorNames = doctorNamesDict
                            self.isLoading = false
                            print("✅ UI update complete. Prescriptions count: \(self.prescriptions.count)")
                        }
                    } catch {
                        print("❌ Error fetching prescriptions: \(error)")
                        print("🔍 Detailed error: \(String(describing: error))")
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                } else {
                    print("❌ Invalid UUID format for patient ID: \(patientIdString)")
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } else {
                print("❌ No patient ID found in UserDefaults")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct RecordCategoryCard<D: View>: View {
    let title: String
    let iconName: String
    let count: Int
    let destination: D
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppConfig.fontColor)
                    
                    Text("\(count) records")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(.vertical, 5)
        }
    }
}

// MARK: - Record Detail View
struct RecordDetailView: View {
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("No records available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(AppConfig.backgroundColor)
    }
}

// MARK: - No Hospital Selected View
struct NoHospitalSelectedView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("No Hospital Selected")
                .font(.title3)
            
            Text("Please select a hospital to view records")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                selectedTab = 0
            }) {
                Text("Go to Home")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConfig.buttonColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 50)
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationView {
        RecordsTabView(selectedHospitalId: .constant(""))
    }
}

extension PrescriptionData {
    var formattedLabTests: [String] {
        guard let tests = labTests else { return [] }
        
        // If tests is already an array, return it
        if tests is [String] {
            return tests
        }
        
        // If tests is a string, split it
        if let testString = tests as? String {
            return testString.split(separator: ",")
                .map { String($0.trimmingCharacters(in: .whitespaces)) }
        }
        
        return []
    }
}
