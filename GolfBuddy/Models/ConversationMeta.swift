import Foundation

struct ConversationMeta: Identifiable {
    let id: String
    let participants: [String]
    var lastMessageText: String?
    var lastMessageSenderId: String?
    var lastMessageTimestamp: Date?
    var unreadCount: Int

    func partnerId(currentUserId: String) -> String? {
        participants.first { $0 != currentUserId }
    }
}
