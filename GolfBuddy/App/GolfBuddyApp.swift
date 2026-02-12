import SwiftUI
import FirebaseAuth

@main
struct GolfBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataService = DataService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var locationService = LocationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataService)
                .environmentObject(notificationService)
                .environmentObject(locationService)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var dataService: DataService
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                ZStack {
                    AppTheme.cream.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(AppTheme.primaryGreen)
                        Text("Loading...")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.mutedText)
                    }
                }
            } else if dataService.currentUser != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: dataService.currentUser != nil)
        .onAppear {
            setupAuthListener()
        }
    }

    private func setupAuthListener() {
        _ = Auth.auth().addStateDidChangeListener { _, firebaseUser in
            if let firebaseUser = firebaseUser {
                Task {
                    await dataService.loadUserProfile(firebaseUserId: firebaseUser.uid)
                    await MainActor.run {
                        isCheckingAuth = false
                    }
                }
            } else {
                Task { @MainActor in
                    dataService.clearLocalState()
                    isCheckingAuth = false
                }
            }
        }
    }
}
