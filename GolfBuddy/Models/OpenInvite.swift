import Foundation
import FirebaseFirestore

enum OpenInviteStatus: String, Codable {
    case open, full, cancelled
}

enum JoinRequestStatus: String, Codable {
    case pending, approved, declined
}

struct JoinRequest: Identifiable, Codable {
    let id: String
    let userId: String
    var status: JoinRequestStatus
    let requestedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        status: JoinRequestStatus = .pending,
        requestedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.status = status
        self.requestedAt = requestedAt
    }

    func toFirestoreMap() -> [String: Any] {
        [
            "id": id,
            "userId": userId,
            "status": status.rawValue,
            "requestedAt": Timestamp(date: requestedAt)
        ]
    }

    init?(fromFirestore data: [String: Any]) {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let statusRaw = data["status"] as? String,
              let status = JoinRequestStatus(rawValue: statusRaw) else { return nil }
        self.id = id
        self.userId = userId
        self.status = status
        self.requestedAt = (data["requestedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}

struct OpenInvite: Identifiable, Codable {
    let id: String
    let creatorId: String
    let courseName: String
    let timeSlot: DayTimeSlot
    let groupSize: Int
    var approvedPlayerIds: [String]
    var joinRequests: [JoinRequest]
    var status: OpenInviteStatus
    let weekendDate: Date
    let createdAt: Date
    let visibleToFriendIds: [String]

    var spotsRemaining: Int { groupSize - approvedPlayerIds.count }
    var isFull: Bool { spotsRemaining <= 0 }

    init(
        id: String = UUID().uuidString,
        creatorId: String,
        courseName: String,
        timeSlot: DayTimeSlot,
        groupSize: Int,
        approvedPlayerIds: [String]? = nil,
        joinRequests: [JoinRequest] = [],
        status: OpenInviteStatus = .open,
        weekendDate: Date = WeekendStatus.nextWeekend(),
        createdAt: Date = Date(),
        visibleToFriendIds: [String] = []
    ) {
        self.id = id
        self.creatorId = creatorId
        self.courseName = courseName
        self.timeSlot = timeSlot
        self.groupSize = groupSize
        self.approvedPlayerIds = approvedPlayerIds ?? [creatorId]
        self.joinRequests = joinRequests
        self.status = status
        self.weekendDate = weekendDate
        self.createdAt = createdAt
        self.visibleToFriendIds = visibleToFriendIds
    }

    func toFirestoreData() -> [String: Any] {
        [
            "id": id,
            "creatorId": creatorId,
            "courseName": courseName,
            "timeSlot": timeSlot.toFirestoreMap(),
            "groupSize": groupSize,
            "approvedPlayerIds": approvedPlayerIds,
            "joinRequests": joinRequests.map { $0.toFirestoreMap() },
            "status": status.rawValue,
            "weekendDate": Timestamp(date: weekendDate),
            "createdAt": Timestamp(date: createdAt),
            "visibleToFriendIds": visibleToFriendIds
        ]
    }

    init?(fromFirestore data: [String: Any]) {
        guard let id = data["id"] as? String,
              let creatorId = data["creatorId"] as? String,
              let courseName = data["courseName"] as? String,
              let timeSlotMap = data["timeSlot"] as? [String: Any],
              let timeSlot = DayTimeSlot(fromFirestore: timeSlotMap),
              let groupSize = data["groupSize"] as? Int,
              let statusRaw = data["status"] as? String,
              let status = OpenInviteStatus(rawValue: statusRaw) else { return nil }
        self.id = id
        self.creatorId = creatorId
        self.courseName = courseName
        self.timeSlot = timeSlot
        self.groupSize = groupSize
        self.approvedPlayerIds = data["approvedPlayerIds"] as? [String] ?? [creatorId]
        self.joinRequests = (data["joinRequests"] as? [[String: Any]])?.compactMap { JoinRequest(fromFirestore: $0) } ?? []
        self.status = status
        self.weekendDate = (data["weekendDate"] as? Timestamp)?.dateValue() ?? Date()
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.visibleToFriendIds = data["visibleToFriendIds"] as? [String] ?? []
    }
}
