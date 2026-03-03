import SwiftUI

@main
struct GolfBuddyApp: App {
    @StateObject private var dataService = DataService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataService)
                .onAppear {
                    NotificationService.shared.requestPermission()
                }
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
    }
}
