import SwiftUI

private struct RootNavigationKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var rootNavigation: Binding<Bool> {
        get { self[RootNavigationKey.self] }
        set { self[RootNavigationKey.self] = newValue }
    }
}

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var navigationPath = NavigationPath()
    @Published var activeTab: Int = 0
    @Published var shouldDismissToRoot: Bool = false
    @Published var isDismissingToRoot: Bool = false
    @Published var shouldDismissDepartmentList: Bool = false
    @Published var selectedTab: Tab = .home
    @Published var preserveDoctorList = false
    @Published var isNavigatingBack = false
    
    enum Tab {
        case home
        case appointments
        case profile
        
        var index: Int {
            switch self {
            case .home: return 0
            case .appointments: return 1
            case .profile: return 2
            }
        }
    }
    
    private init() {
        // Listen for navigation notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToSelectDoctor),
            name: NSNotification.Name("NavigateToSelectDoctor"),
            object: nil
        )
    }
    
    @objc private func handleNavigateToSelectDoctor(_ notification: Notification) {
        print("🔄 NavigationCoordinator: Handling NavigateToSelectDoctor")
        
        // Set navigation flags
        isNavigatingBack = true
        shouldDismissToRoot = true
        shouldDismissDepartmentList = false
        
        // Clear navigation path
        DispatchQueue.main.async {
            self.navigationPath = NavigationPath()
            
            // Reset states after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.shouldDismissToRoot = false
                self.isNavigatingBack = false
                print("🔄 NavigationCoordinator: Reset navigation states")
            }
        }
    }
    
    func resetNavigation() {
        shouldDismissToRoot = false
        isDismissingToRoot = false
        shouldDismissDepartmentList = false
        isNavigatingBack = false
        navigationPath = NavigationPath()
    }
    
    func navigateToDashboard() {
        print("📱 NavigationCoordinator: navigateToDashboard() called")
        
        // Post notification to switch to appointments tab
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToDashboard"), object: nil)
        print("📨 NavigationCoordinator: Posted NavigateToDashboard notification")
        
        // Set state
        isDismissingToRoot = true
        shouldDismissToRoot = true
        shouldDismissDepartmentList = true
        activeTab = 1
        
        // Clear navigation path
        navigationPath = NavigationPath()
        print("🔄 NavigationCoordinator: Cleared navigation path")
        
        // Reset the dismissal state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("⏰ NavigationCoordinator: Resetting navigation states after delay")
            self.shouldDismissToRoot = false
            self.isDismissingToRoot = false
            self.shouldDismissDepartmentList = false
        }
    }
} 