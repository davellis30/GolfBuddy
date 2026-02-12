import Foundation
import Combine
import UIKit

class DataService: ObservableObject {
    static let shared = DataService()

    // MARK: - Published State
    @Published var currentUser: User?
    @Published var allUsers: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var friendships: [UUID: Set<UUID>] = [:] // userId -> set of friend userIds
    @Published var weekendStatuses: [UUID: WeekendStatus] = [:] // userId -> status
    @Published var messages: [Message] = []
    @Published var profilePhotos: [UUID: Data] = [:]
    @Published var appleUserMap: [String: UUID] = [:]

    let courses: [Course] = CourseService.chicagoAreaCourses
    let allCourses: [Course] = CourseService.allCourses

    private init() {
        seedDemoData()
    }

    // MARK: - Auth

    func signUp(username: String, displayName: String, email: String) {
        let user = User(
            id: UUID(),
            username: username,
            displayName: displayName,
            email: email,
            handicap: nil,
            homeCourse: nil
        )
        allUsers.append(user)
        currentUser = user
        friendships[user.id] = []
    }

    func signIn(username: String) -> Bool {
        if let user = allUsers.first(where: { $0.username.lowercased() == username.lowercased() }) {
            currentUser = user
            return true
        }
        return false
    }

    func signOut() {
        currentUser = nil
    }

    func updateProfile(handicap: Double?, homeCourse: String?) {
        guard var user = currentUser else { return }
        user.handicap = handicap
        user.homeCourse = homeCourse
        currentUser = user
        if let idx = allUsers.firstIndex(where: { $0.id == user.id }) {
            allUsers[idx] = user
        }
    }

    // MARK: - Apple Auth

    func signInWithApple(appleUserId: String, email: String?, fullName: PersonNameComponents?) -> User {
        if let existingUser = getUserByAppleId(appleUserId) {
            currentUser = existingUser
            return existingUser
        }

        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let finalDisplayName = displayName.isEmpty ? "Apple User" : displayName
        let finalEmail = email ?? ""
        let username = "apple_\(UUID().uuidString.prefix(8))"

        let user = User(
            id: UUID(),
            username: username,
            displayName: finalDisplayName,
            email: finalEmail,
            handicap: nil,
            homeCourse: nil
        )

        allUsers.append(user)
        appleUserMap[appleUserId] = user.id
        friendships[user.id] = []
        currentUser = user
        return user
    }

    func getUserByAppleId(_ appleUserId: String) -> User? {
        guard let userId = appleUserMap[appleUserId] else { return nil }
        return allUsers.first(where: { $0.id == userId })
    }

    // MARK: - Profile Photos

    func setProfilePhoto(for userId: UUID, imageData: Data?) {
        if let data = imageData {
            profilePhotos[userId] = processProfileImage(data)
        } else {
            profilePhotos.removeValue(forKey: userId)
        }
    }

    private func processProfileImage(_ data: Data) -> Data? {
        guard let uiImage = UIImage(data: data) else { return data }
        let maxDimension: CGFloat = 512
        let scale = min(maxDimension / uiImage.size.width, maxDimension / uiImage.size.height, 1.0)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }

    // MARK: - Friends

    func sendFriendRequest(to userId: UUID) {
        guard let currentId = currentUser?.id else { return }
        let existing = friendRequests.first {
            ($0.fromUserId == currentId && $0.toUserId == userId) ||
            ($0.fromUserId == userId && $0.toUserId == currentId)
        }
        guard existing == nil else { return }
        guard !(friendships[currentId]?.contains(userId) ?? false) else { return }

        let request = FriendRequest(fromUserId: currentId, toUserId: userId)
        friendRequests.append(request)
    }

    func acceptFriendRequest(_ request: FriendRequest) {
        guard let idx = friendRequests.firstIndex(where: { $0.id == request.id }) else { return }
        friendRequests[idx].status = .accepted

        friendships[request.fromUserId, default: []].insert(request.toUserId)
        friendships[request.toUserId, default: []].insert(request.fromUserId)
    }

    func declineFriendRequest(_ request: FriendRequest) {
        guard let idx = friendRequests.firstIndex(where: { $0.id == request.id }) else { return }
        friendRequests[idx].status = .declined
    }

    func removeFriend(_ friendId: UUID) {
        guard let currentId = currentUser?.id else { return }
        friendships[currentId]?.remove(friendId)
        friendships[friendId]?.remove(currentId)
    }

    func friends(of userId: UUID) -> [User] {
        let friendIds = friendships[userId] ?? []
        return allUsers.filter { friendIds.contains($0.id) }
    }

    func pendingRequestsForCurrentUser() -> [FriendRequest] {
        guard let currentId = currentUser?.id else { return [] }
        return friendRequests.filter { $0.toUserId == currentId && $0.status == .pending }
    }

    func sentRequestsForCurrentUser() -> [FriendRequest] {
        guard let currentId = currentUser?.id else { return [] }
        return friendRequests.filter { $0.fromUserId == currentId && $0.status == .pending }
    }

    func isFriend(_ userId: UUID) -> Bool {
        guard let currentId = currentUser?.id else { return false }
        return friendships[currentId]?.contains(userId) ?? false
    }

    func hasPendingRequest(with userId: UUID) -> Bool {
        guard let currentId = currentUser?.id else { return false }
        return friendRequests.contains {
            $0.status == .pending &&
            (($0.fromUserId == currentId && $0.toUserId == userId) ||
             ($0.fromUserId == userId && $0.toUserId == currentId))
        }
    }

    func searchUsers(query: String) -> [User] {
        guard let currentId = currentUser?.id else { return [] }
        let lowered = query.lowercased()
        return allUsers.filter {
            $0.id != currentId &&
            ($0.username.lowercased().contains(lowered) ||
             $0.displayName.lowercased().contains(lowered))
        }
    }

    // MARK: - Weekend Status

    func setWeekendStatus(
        availability: WeekendAvailability,
        isVisible: Bool,
        shareDetails: Bool,
        courseName: String?,
        playingWith: [UUID],
        timeSlots: [DayTimeSlot] = [],
        preferredTimeSlot: DayTimeSlot? = nil
    ) {
        guard let currentId = currentUser?.id else { return }
        let status = WeekendStatus(
            userId: currentId,
            availability: availability,
            isVisible: isVisible,
            shareDetails: shareDetails,
            courseName: courseName,
            playingWith: playingWith,
            timeSlots: timeSlots,
            preferredTimeSlot: preferredTimeSlot
        )
        weekendStatuses[currentId] = status
    }

    func clearWeekendStatus() {
        guard let currentId = currentUser?.id else { return }
        weekendStatuses.removeValue(forKey: currentId)
    }

    func visibleFriendStatuses() -> [(User, WeekendStatus)] {
        guard let currentId = currentUser?.id else { return [] }
        let friendIds = friendships[currentId] ?? []
        var results: [(User, WeekendStatus)] = []
        for friendId in friendIds {
            if let status = weekendStatuses[friendId], status.isVisible,
               let user = allUsers.first(where: { $0.id == friendId }) {
                results.append((user, status))
            }
        }
        return results.sorted { $0.1.availability.rawValue < $1.1.availability.rawValue }
    }

    func userName(for id: UUID) -> String {
        allUsers.first(where: { $0.id == id })?.displayName ?? "Unknown"
    }

    // MARK: - Messages

    func sendMessage(to userId: UUID, text: String) {
        guard let currentId = currentUser?.id else { return }
        let message = Message(senderId: currentId, receiverId: userId, text: text)
        messages.append(message)
    }

    func messages(with userId: UUID) -> [Message] {
        guard let currentId = currentUser?.id else { return [] }
        return messages.filter {
            ($0.senderId == currentId && $0.receiverId == userId) ||
            ($0.senderId == userId && $0.receiverId == currentId)
        }.sorted { $0.timestamp < $1.timestamp }
    }

    func unreadCount(from userId: UUID) -> Int {
        guard let currentId = currentUser?.id else { return 0 }
        return messages.filter {
            $0.senderId == userId && $0.receiverId == currentId && !$0.isRead
        }.count
    }

    func markMessagesAsRead(from userId: UUID) {
        guard let currentId = currentUser?.id else { return }
        for i in messages.indices {
            if messages[i].senderId == userId && messages[i].receiverId == currentId && !messages[i].isRead {
                messages[i].isRead = true
            }
        }
    }

    // MARK: - Demo Data

    private func seedDemoData() {
        let demo1 = User(id: UUID(), username: "mikej", displayName: "Mike Johnson", email: "mike@example.com", handicap: 12.4, homeCourse: "Jackson Park Golf Course")
        let demo2 = User(id: UUID(), username: "sarahw", displayName: "Sarah Williams", email: "sarah@example.com", handicap: 8.1, homeCourse: "Harborside International Golf Center")
        let demo3 = User(id: UUID(), username: "davepark", displayName: "Dave Parker", email: "dave@example.com", handicap: 18.5, homeCourse: "Sydney R. Marovitz Golf Course")
        let demo4 = User(id: UUID(), username: "lisam", displayName: "Lisa Martinez", email: "lisa@example.com", handicap: 15.0, homeCourse: "Indian Boundary Golf Course")
        let demo5 = User(id: UUID(), username: "tomk", displayName: "Tom Kim", email: "tom@example.com", handicap: 5.2, homeCourse: "Cog Hill Golf & Country Club (Course 1)")
        let demo6 = User(id: UUID(), username: "jennyr", displayName: "Jenny Rodriguez", email: "jenny@example.com", handicap: 22.0, homeCourse: nil)

        allUsers = [demo1, demo2, demo3, demo4, demo5, demo6]

        // Pre-build some friendships between demo users
        friendships[demo1.id] = [demo2.id, demo3.id, demo5.id]
        friendships[demo2.id] = [demo1.id, demo3.id, demo4.id]
        friendships[demo3.id] = [demo1.id, demo2.id]
        friendships[demo4.id] = [demo2.id]
        friendships[demo5.id] = [demo1.id]
        friendships[demo6.id] = []

        // Some demo statuses
        weekendStatuses[demo1.id] = WeekendStatus(
            userId: demo1.id,
            availability: .lookingToPlay,
            isVisible: true,
            shareDetails: false,
            timeSlots: [DayTimeSlot(day: .saturday, time: .am)],
            preferredTimeSlot: DayTimeSlot(day: .saturday, time: .am)
        )
        weekendStatuses[demo2.id] = WeekendStatus(
            userId: demo2.id,
            availability: .alreadyPlaying,
            isVisible: true,
            shareDetails: true,
            courseName: "Harborside International Golf Center",
            playingWith: [demo4.id],
            timeSlots: [DayTimeSlot(day: .sunday, time: .pm)]
        )
        weekendStatuses[demo3.id] = WeekendStatus(
            userId: demo3.id,
            availability: .seekingAdditional,
            isVisible: true,
            shareDetails: true,
            courseName: "Sydney R. Marovitz Golf Course",
            playingWith: [],
            timeSlots: [DayTimeSlot(day: .saturday, time: .am), DayTimeSlot(day: .saturday, time: .pm)],
            preferredTimeSlot: DayTimeSlot(day: .saturday, time: .am)
        )
        weekendStatuses[demo5.id] = WeekendStatus(
            userId: demo5.id,
            availability: .alreadyPlaying,
            isVisible: false, // hidden
            shareDetails: false
        )

        // Demo messages (will be visible once a user logs in as demo1/mikej)
        let now = Date()
        messages = [
            Message(senderId: demo1.id, receiverId: demo2.id, text: "Hey Sarah, are you playing this weekend?", timestamp: now.addingTimeInterval(-7200), isRead: true),
            Message(senderId: demo2.id, receiverId: demo1.id, text: "Yes! Thinking about Harborside. Want to join?", timestamp: now.addingTimeInterval(-6800), isRead: true),
            Message(senderId: demo1.id, receiverId: demo2.id, text: "Sounds great! What time are you thinking?", timestamp: now.addingTimeInterval(-6400), isRead: true),
            Message(senderId: demo2.id, receiverId: demo1.id, text: "How about 8am tee time?", timestamp: now.addingTimeInterval(-3600), isRead: false),
            Message(senderId: demo3.id, receiverId: demo1.id, text: "Mike, need a 4th for Saturday at Marovitz. You in?", timestamp: now.addingTimeInterval(-1800), isRead: false),
        ]
    }
}
