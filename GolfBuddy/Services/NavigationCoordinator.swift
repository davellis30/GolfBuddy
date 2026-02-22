import SwiftUI

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    @Published var selectedTab: Int = 0
    @Published var pendingDeepLink: PushNotificationPayload?

    private init() {}

    func handleNotificationTap(_ payload: PushNotificationPayload) {
        DispatchQueue.main.async {
            self.pendingDeepLink = payload

            switch payload.type {
            case .friendRequest:
                self.selectedTab = 1 // Friends tab
            case .message:
                self.selectedTab = 2 // Messages tab
            case .statusChange:
                self.selectedTab = 0 // Weekend tab
            }
        }
    }

    func consumeDeepLink() -> PushNotificationPayload? {
        let link = pendingDeepLink
        pendingDeepLink = nil
        return link
    }
}
