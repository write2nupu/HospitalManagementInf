//@MainActor
//class HospitalManagementViewModel: ObservableObject {
//    @Published private(set) var doctors: [Doctor] = []
//    // ... other properties
//    
//    func addDoctor(_ doctor: Doctor) throws {
//        do {
//            try dataController.addDoctor(doctor)
//            // Make sure to update the local doctors array
//            doctors.append(doctor)
//            // Notify views of the change
//            objectWillChange.send()
//        } catch {
//            throw error
//        }
//    }
//    
//    func getDoctorsByHospital(hospitalId: UUID) -> [Doctor] {
//        return doctors.filter { $0.hospitalId == hospitalId }
//    }
//} 
