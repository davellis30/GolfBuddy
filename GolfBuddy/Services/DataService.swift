import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()

    // MARK: - Published State
    @Published var currentUser: User?
    @Published var allUsers: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var friendships: [UUID: Set<UUID>] = [:] // userId -> set of friend userIds
    @Published var weekendStatuses: [UUID: WeekendStatus] = [:] // userId -> status

    let courses: [Course] = CourseService.chicagoPublicCourses.sorted { $0.distanceFromChicago < $1.distanceFromChicago }

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
        playingWith: [UUID]
    ) {
        guard let currentId = currentUser?.id else { return }
        let status = WeekendStatus(
            userId: currentId,
            availability: availability,
            isVisible: isVisible,
            shareDetails: shareDetails,
            courseName: courseName,
            playingWith: playingWith
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
            shareDetails: false
        )
        weekendStatuses[demo2.id] = WeekendStatus(
            userId: demo2.id,
            availability: .alreadyPlaying,
            isVisible: true,
            shareDetails: true,
            courseName: "Harborside International Golf Center",
            playingWith: [demo4.id]
        )
        weekendStatuses[demo3.id] = WeekendStatus(
            userId: demo3.id,
            availability: .seekingAdditional,
            isVisible: true,
            shareDetails: true,
            courseName: "Sydney R. Marovitz Golf Course",
            playingWith: []
        )
        weekendStatuses[demo5.id] = WeekendStatus(
            userId: demo5.id,
            availability: .alreadyPlaying,
            isVisible: false, // hidden
            shareDetails: false
        )
    }
}
