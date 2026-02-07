import Foundation

enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct FriendRequest: Identifiable, Codable {
    let id: UUID
    let fromUserId: UUID
    let toUserId: UUID
    var status: FriendRequestStatus
    let sentAt: Date

    init(
        id: UUID = UUID(),
        fromUserId: UUID,
        toUserId: UUID,
        status: FriendRequestStatus = .pending,
        sentAt: Date = Date()
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.sentAt = sentAt
    }
}
