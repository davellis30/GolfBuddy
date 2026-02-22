import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]

    private init() {}

    // MARK: - Canonical IDs

    static func canonicalId(_ id1: String, _ id2: String) -> String {
        [id1, id2].sorted().joined(separator: "_")
    }

    // MARK: - Listener Management

    func removeAllListeners() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }

    func removeListener(named name: String) {
        listeners[name]?.remove()
        listeners.removeValue(forKey: name)
    }

    // MARK: - Users

    func searchUsers(query: String, excludingUserId: String) async throws -> [User] {
        let trimmed = query.hasPrefix("@") ? String(query.dropFirst()) : query
        let lowered = trimmed.lowercased()
        let end = lowered + "\u{f8ff}"

        let usernameSnapshot = try await db.collection("users")
            .whereField("usernameLower", isGreaterThanOrEqualTo: lowered)
            .whereField("usernameLower", isLessThan: end)
            .limit(to: 20)
            .getDocuments()

        let displayNameSnapshot = try await db.collection("users")
            .whereField("displayNameLower", isGreaterThanOrEqualTo: lowered)
            .whereField("displayNameLower", isLessThan: end)
            .limit(to: 20)
            .getDocuments()

        var seen = Set<String>()
        var users: [User] = []
        for doc in usernameSnapshot.documents + displayNameSnapshot.documents {
            let id = doc.documentID
            guard id != excludingUserId, !seen.contains(id) else { continue }
            seen.insert(id)
            var data = doc.data()
            data["id"] = id
            if let user = User(fromFirestore: data) {
                users.append(user)
            }
        }
        return users
    }

    func fetchUser(userId: String) async throws -> User {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard var data = doc.data() else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        data["id"] = doc.documentID
        guard let user = User(fromFirestore: data) else {
            throw NSError(domain: "FirestoreService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        return user
    }

    // MARK: - Friend Requests

    func startFriendRequestsListener(userId: String, onChange: @escaping ([FriendRequest]) -> Void) {
        removeListener(named: "friendRequests")

        let listener = db.collection("friendRequests")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let requests = docs.compactMap { FriendRequest(fromFirestore: $0.data()) }
                onChange(requests)
            }
        listeners["friendRequests"] = listener
    }

    func sendFriendRequest(from senderId: String, to receiverId: String) async throws -> FriendRequest {
        let request = FriendRequest(fromUserId: senderId, toUserId: receiverId)
        try await db.collection("friendRequests").document(request.id).setData(request.toFirestoreData())
        return request
    }

    func acceptFriendRequest(_ request: FriendRequest) async throws {
        let friendshipId = Self.canonicalId(request.fromUserId, request.toUserId)

        _ = try await db.runTransaction { transaction, _ in
            let requestRef = self.db.collection("friendRequests").document(request.id)
            transaction.updateData(["status": "accepted"], forDocument: requestRef)

            let friendshipRef = self.db.collection("friendships").document(friendshipId)
            transaction.setData([
                "id": friendshipId,
                "userIds": [request.fromUserId, request.toUserId].sorted(),
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: friendshipRef)

            return nil
        }
    }

    func declineFriendRequest(_ requestId: String) async throws {
        try await db.collection("friendRequests").document(requestId).updateData(["status": "declined"])
    }

    // MARK: - Friendships

    func startFriendshipsListener(userId: String, onChange: @escaping (Set<String>) -> Void) {
        removeListener(named: "friendships")

        let listener = db.collection("friendships")
            .whereField("userIds", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                var friendIds = Set<String>()
                for doc in docs {
                    if let userIds = doc.data()["userIds"] as? [String] {
                        for id in userIds where id != userId {
                            friendIds.insert(id)
                        }
                    }
                }
                onChange(friendIds)
            }
        listeners["friendships"] = listener
    }

    func removeFriendship(userId: String, friendId: String) async throws {
        let friendshipId = Self.canonicalId(userId, friendId)
        try await db.collection("friendships").document(friendshipId).delete()
    }

    // MARK: - Weekend Statuses

    func startStatusesListener(userIds: [String], onChange: @escaping ([String: WeekendStatus]) -> Void) {
        removeListener(named: "statuses")
        guard !userIds.isEmpty else {
            onChange([:])
            return
        }

        // Firestore 'in' query supports up to 30 values
        let batchIds = Array(userIds.prefix(30))

        let listener = db.collection("weekendStatuses")
            .whereField("userId", in: batchIds)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                var statuses: [String: WeekendStatus] = [:]
                for doc in docs {
                    if let status = WeekendStatus(fromFirestore: doc.data()) {
                        statuses[status.userId] = status
                    }
                }
                onChange(statuses)
            }
        listeners["statuses"] = listener
    }

    func setWeekendStatus(_ status: WeekendStatus) async throws {
        try await db.collection("weekendStatuses").document(status.userId).setData(status.toFirestoreData())
    }

    func clearWeekendStatus(userId: String) async throws {
        try await db.collection("weekendStatuses").document(userId).delete()
    }

    // MARK: - Conversations

    func startConversationsListener(userId: String, onChange: @escaping ([ConversationMeta]) -> Void) {
        removeListener(named: "conversations")

        let listener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("[FirestoreService] Conversations listener error: \(error)")
                }
                guard let docs = snapshot?.documents else { return }
                let conversations = docs.compactMap { doc -> ConversationMeta? in
                    let data = doc.data()
                    let participants = data["participants"] as? [String] ?? []
                    let lastMsg = data["lastMessage"] as? [String: Any]
                    let unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]

                    return ConversationMeta(
                        id: doc.documentID,
                        participants: participants,
                        lastMessageText: lastMsg?["text"] as? String,
                        lastMessageSenderId: lastMsg?["senderId"] as? String,
                        lastMessageTimestamp: (lastMsg?["timestamp"] as? Timestamp)?.dateValue(),
                        unreadCount: unreadCounts[userId] ?? 0
                    )
                }
                onChange(conversations)
            }
        listeners["conversations"] = listener
    }

    func startMessagesListener(conversationId: String, onChange: @escaping ([Message]) -> Void) {
        let listenerName = "messages-\(conversationId)"
        removeListener(named: listenerName)

        let listener = db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let messages = docs.compactMap { Message(fromFirestore: $0.data()) }
                onChange(messages)
            }
        listeners[listenerName] = listener
    }

    func sendMessage(from senderId: String, to receiverId: String, text: String) async throws {
        let convoId = Self.canonicalId(senderId, receiverId)
        let messageId = UUID().uuidString
        let timestamp = Timestamp(date: Date())

        let batch = db.batch()

        let convoRef = db.collection("conversations").document(convoId)
        batch.setData([
            "participants": [senderId, receiverId].sorted(),
            "lastMessage": [
                "text": text,
                "senderId": senderId,
                "timestamp": timestamp
            ],
            "lastMessageTimestamp": timestamp,
            "unreadCounts.\(receiverId)": FieldValue.increment(Int64(1))
        ], forDocument: convoRef, merge: true)

        let messageRef = convoRef.collection("messages").document(messageId)
        batch.setData([
            "id": messageId,
            "senderId": senderId,
            "receiverId": receiverId,
            "text": text,
            "timestamp": timestamp,
            "isRead": false
        ], forDocument: messageRef)

        try await batch.commit()
    }

    func markMessagesAsRead(conversationId: String, userId: String) async throws {
        // Reset unread count for this user on the conversation doc
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCounts.\(userId)": 0
        ])

        // Mark individual messages as read
        let snapshot = try await db.collection("conversations").document(conversationId)
            .collection("messages")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    // MARK: - Notification Preferences

    func fetchNotificationPreferences(userId: String) async throws -> NotificationPreferences {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data(),
              let prefsData = data["notificationPreferences"] as? [String: Any] else {
            return .defaults
        }
        return NotificationPreferences(fromFirestore: prefsData) ?? .defaults
    }

    func updateNotificationPreferences(userId: String, prefs: NotificationPreferences) async throws {
        try await db.collection("users").document(userId).updateData([
            "notificationPreferences": prefs.toFirestoreData()
        ])
    }

    // MARK: - Account Deletion

    func deleteAllUserData(userId: String) async throws {
        // Delete user profile
        try await db.collection("users").document(userId).delete()

        // Delete weekend status
        try await db.collection("weekendStatuses").document(userId).delete()

        // Delete friend requests involving this user
        let requestSnapshot = try await db.collection("friendRequests")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        for doc in requestSnapshot.documents {
            try await doc.reference.delete()
        }

        // Delete friendships involving this user
        let friendshipSnapshot = try await db.collection("friendships")
            .whereField("userIds", arrayContains: userId)
            .getDocuments()
        for doc in friendshipSnapshot.documents {
            try await doc.reference.delete()
        }

        // Delete conversations and their messages
        let convoSnapshot = try await db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        for doc in convoSnapshot.documents {
            // Delete all messages in the conversation
            let messagesSnapshot = try await doc.reference.collection("messages").getDocuments()
            let batch = db.batch()
            for msgDoc in messagesSnapshot.documents {
                batch.deleteDocument(msgDoc.reference)
            }
            batch.deleteDocument(doc.reference)
            try await batch.commit()
        }
    }
}
