//import Foundation
//
//struct LabTest: Codable, Identifiable {
//    let id: UUID
//    let bookingId: UUID
//    let testName: String
//    let status: TestStatus
//    let testDate: Date
//    let testValue: Float
//    let components: [String]?
//    let labTestPrice: Double
//    let hospitalid: UUID
//    let prescriptionId: UUID?
//    let patientid: UUID
//    
//    enum TestStatus: String, Codable {
//        case pending = "Pending"
//        case completed = "Completed"
//    }
//    
//    enum LabTestName: String, Codable, CaseIterable {
//        case completeBloodCount = "Complete Blood Count"
//        case bloodSugarTest = "Blood Sugar Test"
//        case lipidProfile = "Lipid Profile"
//        case thyroidFunctionTest = "Thyroid Function Test"
//        case liverFunctionTest = "Liver Function Test"
//        case kidneyFunctionTest = "Kidney Function Test"
//        case urineAnalysis = "Urine Analysis"
//        case vitaminDTest = "Vitamin D Test"
//        case vitaminB12Test = "Vitamin B12 Test"
//        case calciumTest = "Calcium Test"
//        case cReactiveProtein = "C-Reactive Protein (CRP)"
//        case erythrocyteSedimentationRate = "Erythrocyte Sedimentation Rate (ESR)"
//        case hba1c = "HbA1c"
//        case bloodCulture = "Blood Culture"
//        case urineCulture = "Urine Culture"
//        case fastingBloodSugar = "Fasting Blood Sugar"
//        case postprandialBloodSugar = "Postprandial Blood Sugar"
//        
//        var price: Double {
//            switch self {
//            case .completeBloodCount: return 500
//            case .bloodSugarTest: return 300
//            case .lipidProfile: return 800
//            case .thyroidFunctionTest: return 1200
//            case .liverFunctionTest: return 1000
//            case .kidneyFunctionTest: return 1000
//            case .urineAnalysis: return 400
//            case .vitaminDTest: return 900
//            case .vitaminB12Test: return 800
//            case .calciumTest: return 400
//            case .cReactiveProtein: return 600
//            case .erythrocyteSedimentationRate: return 400
//            case .hba1c: return 700
//            case .bloodCulture: return 1000
//            case .urineCulture: return 800
//            case .fastingBloodSugar: return 300
//            case .postprandialBloodSugar: return 300
//            }
//        }
//    }
//} 
