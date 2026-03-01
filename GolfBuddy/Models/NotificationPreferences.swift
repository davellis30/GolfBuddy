import Foundation

struct NotificationPreferences: Codable {
    var friendRequests: Bool
    var messages: Bool
    var statusChanges: Bool
    var invites: Bool

    static let defaults = NotificationPreferences(
        friendRequests: true,
        messages: true,
        statusChanges: true,
        invites: true
    )
}

extension NotificationPreferences {
    init?(fromFirestore data: [String: Any]) {
        self.friendRequests = data["friendRequests"] as? Bool ?? true
        self.messages = data["messages"] as? Bool ?? true
        self.statusChanges = data["statusChanges"] as? Bool ?? true
        self.invites = data["invites"] as? Bool ?? true
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "friendRequests": friendRequests,
            "messages": messages,
            "statusChanges": statusChanges,
            "invites": invites
        ]
    }
}
