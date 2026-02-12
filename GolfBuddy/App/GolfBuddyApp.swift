import SwiftUI
import AuthenticationServices

@main
struct GolfBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataService = DataService.shared
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataService)
                .environmentObject(notificationService)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var dataService: DataService

    var body: some View {
        Group {
            if dataService.currentUser != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: dataService.currentUser != nil)
        .onAppear {
            if let storedAppleId = UserDefaults.standard.string(forKey: "storedAppleUserId") {
                Task {
                    let state = await AppleAuthService.shared.checkCredentialState(for: storedAppleId)
                    await MainActor.run {
                        if state == .authorized, let user = dataService.getUserByAppleId(storedAppleId) {
                            dataService.currentUser = user
                        } else {
                            AppleAuthService.shared.clearStoredAppleId()
                        }
                    }
                }
            }
        }
    }
}
