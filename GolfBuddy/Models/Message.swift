import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date
    var isRead: Bool

    init(id: String = UUID().uuidString, senderId: String, receiverId: String, text: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }

    func toFirestoreData() -> [String: Any] {
        [
            "id": id,
            "senderId": senderId,
            "receiverId": receiverId,
            "text": text,
            "timestamp": Timestamp(date: timestamp),
            "isRead": isRead
        ]
    }

    init?(fromFirestore data: [String: Any]) {
        guard let id = data["id"] as? String,
              let senderId = data["senderId"] as? String,
              let receiverId = data["receiverId"] as? String,
              let text = data["text"] as? String else { return nil }
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.isRead = data["isRead"] as? Bool ?? false
    }
}
