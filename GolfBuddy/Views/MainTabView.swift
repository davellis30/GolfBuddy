import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StatusDashboardView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Weekend")
                }
                .tag(0)

            FriendsListView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag(1)

            MessagesListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Messages")
                }
                .tag(2)

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
}
