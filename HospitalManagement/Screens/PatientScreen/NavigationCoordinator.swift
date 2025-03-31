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
    
    @Published var activeTab: Int = 0 {
        didSet {
            print("🔄 NavigationCoordinator: activeTab changed from \(oldValue) to \(activeTab)")
        }
    }
    
    @Published var shouldDismissToRoot: Bool = false {
        didSet {
            print("🔄 NavigationCoordinator: shouldDismissToRoot changed from \(oldValue) to \(shouldDismissToRoot)")
        }
    }
    
    @Published var navigationPath = NavigationPath() {
        didSet {
            print("🔄 NavigationCoordinator: navigationPath changed")
        }
    }
    
    @Published var isDismissingToRoot: Bool = false {
        didSet {
            print("🔄 NavigationCoordinator: isDismissingToRoot changed from \(oldValue) to \(isDismissingToRoot)")
        }
    }
    
    @Published var shouldDismissDepartmentList: Bool = false {
        didSet {
            print("🔄 NavigationCoordinator: shouldDismissDepartmentList changed from \(oldValue) to \(shouldDismissDepartmentList)")
        }
    }
    
    @Published var selectedTab: Tab = .home {
        didSet {
            print("🔄 NavigationCoordinator: selectedTab changed from \(oldValue) to \(selectedTab)")
        }
    }
    
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