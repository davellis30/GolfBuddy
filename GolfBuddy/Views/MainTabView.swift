import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0

    private var weekendBadge: Int {
        guard let userId = dataService.currentUser?.id else { return 0 }
        return dataService.weekendStatuses[userId] == nil ? 1 : 0
    }

    private var friendsBadge: Int {
        dataService.pendingRequestsForCurrentUser().count
    }

    private var messagesBadge: Int {
        dataService.conversationMetadata.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        VStack(spacing: 0) {
            if dataService.showVerificationBanner {
                EmailVerificationBanner()
            }

            TabView(selection: $selectedTab) {
                StatusDashboardView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Weekend")
                    }
                    .tag(0)
                    .badge(weekendBadge)

                FriendsListView()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Friends")
                    }
                    .tag(1)
                    .badge(friendsBadge)

                MessagesListView()
                    .tabItem {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Messages")
                    }
                    .tag(2)
                    .badge(messagesBadge)

                CourseListView()
                    .tabItem {
                        Image(systemName: "flag.fill")
                        Text("Courses")
                    }
                    .tag(3)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                        Text("Profile")
                    }
                    .tag(4)
            }
            .tint(AppTheme.accentGreen)
        }
        .task {
            if notificationService.permissionStatus == .notDetermined {
                await notificationService.requestPermission()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && dataService.showVerificationBanner {
                dataService.checkEmailVerification()
            }
        }
    }
}
