import Foundation
import FirebaseFirestore

enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    var status: FriendRequestStatus
    let sentAt: Date

    init(
        id: String = UUID().uuidString,
        fromUserId: String,
        toUserId: String,
        status: FriendRequestStatus = .pending,
        sentAt: Date = Date()
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.sentAt = sentAt
    }

    func toFirestoreData() -> [String: Any] {
        [
            "id": id,
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "status": status.rawValue,
            "sentAt": Timestamp(date: sentAt),
            "participants": [fromUserId, toUserId]
        ]
    }

    init?(fromFirestore data: [String: Any]) {
        guard let id = data["id"] as? String,
              let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let statusRaw = data["status"] as? String,
              let status = FriendRequestStatus(rawValue: statusRaw) else { return nil }
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.sentAt = (data["sentAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
