import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let text: String
    let timestamp: Date
    var isRead: Bool

    init(id: UUID = UUID(), senderId: UUID, receiverId: UUID, text: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }
}
