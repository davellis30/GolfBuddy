import Foundation

enum PushNotificationType: String {
    case friendRequest
    case message
    case statusChange
}

struct PushNotificationPayload {
    let type: PushNotificationType
    let requestId: String?
    let conversationId: String?
    let senderId: String?
    let statusUserId: String?

    init?(userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String,
              let type = PushNotificationType(rawValue: typeString) else {
            return nil
        }
        self.type = type
        self.requestId = userInfo["requestId"] as? String
        self.conversationId = userInfo["conversationId"] as? String
        self.senderId = userInfo["senderId"] as? String
        self.statusUserId = userInfo["statusUserId"] as? String
    }
}
