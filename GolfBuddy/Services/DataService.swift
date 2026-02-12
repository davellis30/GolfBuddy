import Foundation
import Combine
import UIKit
import AuthenticationServices
import CoreLocation

class DataService: ObservableObject, @unchecked Sendable {
    static let shared = DataService()

    // MARK: - Published State
    @Published var currentUser: User?
    @Published var allUsers: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var friendships: [String: Set<String>] = [:] // userId -> set of friend userIds
    @Published var weekendStatuses: [String: WeekendStatus] = [:] // userId -> status
    @Published var messages: [Message] = [] // kept for backward compat, but not primary source
    @Published var profilePhotos: [String: Data] = [:]
    @Published var conversationMetadata: [ConversationMeta] = []
    @Published var activeConversationMessages: [Message] = []
    @Published var nearbyCourses: [Course] = CourseService.chicagoAreaCourses

    let allCourses: [Course] = CourseService.allCourses

    private let firestoreService = FirestoreService.shared
    private let locationService = LocationService.shared
    private var activeConversationId: String?
    private var locationCancellable: AnyCancellable?

    private init() {
        locationCancellable = locationService.$userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                let nearby = CourseService.nearbyCourses(from: location)
                DispatchQueue.main.async {
                    self?.nearbyCourses = nearby
                }
            }
    }

    // MARK: - Auth

    func signUp(username: String, displayName: String, email: String, password: String) async throws {
        let user = try await FirebaseAuthService.shared.signUp(
            email: email,
            password: password,
            username: username,
            displayName: displayName
        )
        await MainActor.run {
            self.allUsers.append(user)
            self.currentUser = user
            self.friendships[user.id] = []
        }
        await startListeners()
    }

    func signIn(email: String, password: String) async throws {
        let user = try await FirebaseAuthService.shared.signIn(email: email, password: password)
        await MainActor.run {
            if !self.allUsers.contains(where: { $0.id == user.id }) {
                self.allUsers.append(user)
            }
            self.currentUser = user
        }
        await startListeners()
    }

    func signInWithApple(credential: Any) async throws {
        guard let appleCredential = credential as? AuthenticationServices.ASAuthorizationAppleIDCredential else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"])
        }
        let user = try await FirebaseAuthService.shared.signInWithApple(credential: appleCredential)
        await MainActor.run {
            if !self.allUsers.contains(where: { $0.id == user.id }) {
                self.allUsers.append(user)
            }
            self.currentUser = user
            self.friendships[user.id] = self.friendships[user.id] ?? []
        }
        await startListeners()
    }

    func signOut() {
        try? FirebaseAuthService.shared.signOut()
        clearLocalState()
    }

    func clearLocalState() {
        firestoreService.removeAllListeners()
        activeConversationId = nil
        currentUser = nil
        allUsers = []
        friendRequests = []
        friendships = [:]
        weekendStatuses = [:]
        messages = []
        profilePhotos = [:]
        conversationMetadata = []
        activeConversationMessages = []
    }

    func deleteAccount() async throws {
        guard let userId = currentUser?.id else { return }
        firestoreService.removeAllListeners()
        try await firestoreService.deleteAllUserData(userId: userId)
        try await FirebaseAuthService.shared.deleteAccount()
        await MainActor.run {
            self.clearLocalState()
        }
    }

    func loadUserProfile(firebaseUserId: String) async {
        guard let user = try? await FirebaseAuthService.shared.loadUserProfile(firebaseUserId: firebaseUserId) else { return }
        await MainActor.run {
            if !self.allUsers.contains(where: { $0.id == user.id }) {
                self.allUsers.append(user)
            }
            self.currentUser = user
        }
        await startListeners()
    }

    func updateProfile(handicap: Double?, homeCourse: String?) async throws {
        guard var user = currentUser else { return }
        user.handicap = handicap
        user.homeCourse = homeCourse
        currentUser = user
        if let idx = allUsers.firstIndex(where: { $0.id == user.id }) {
            allUsers[idx] = user
        }
        try await FirebaseAuthService.shared.updateUserProfile(
            firebaseUserId: user.id,
            handicap: handicap,
            homeCourse: homeCourse
        )
    }

    // MARK: - Listeners

    func startListeners() async {
        guard let userId = currentUser?.id else { return }

        firestoreService.startFriendRequestsListener(userId: userId) { @Sendable [weak self] requests in
            DispatchQueue.main.async {
                self?.friendRequests = requests
                // Fetch profiles for request senders/recipients so they render in the UI
                let userIds = Set(requests.flatMap { [$0.fromUserId, $0.toUserId] })
                self?.fetchMissingUserProfiles(friendIds: userIds)
            }
        }

        firestoreService.startFriendshipsListener(userId: userId) { @Sendable [weak self] friendIds in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.friendships[userId] = friendIds
                self.startStatusesListener(friendIds: friendIds, currentUserId: userId)
                self.fetchMissingUserProfiles(friendIds: friendIds)
            }
        }

        firestoreService.startConversationsListener(userId: userId) { @Sendable [weak self] conversations in
            DispatchQueue.main.async {
                self?.conversationMetadata = conversations
                // Fetch user profiles for conversation partners
                let partnerIds = Set(conversations.compactMap { $0.partnerId(currentUserId: userId) })
                self?.fetchMissingUserProfiles(friendIds: partnerIds)
            }
        }
    }

    private func startStatusesListener(friendIds: Set<String>, currentUserId: String) {
        var ids = Array(friendIds)
        ids.append(currentUserId)
        firestoreService.startStatusesListener(userIds: ids) { @Sendable [weak self] statuses in
            DispatchQueue.main.async {
                self?.weekendStatuses = statuses
            }
        }
    }

    private func fetchMissingUserProfiles(friendIds: Set<String>) {
        let missing = friendIds.filter { id in
            !allUsers.contains(where: { $0.id == id })
        }
        for userId in missing {
            Task {
                if let user = try? await firestoreService.fetchUser(userId: userId) {
                    await MainActor.run {
                        if !self.allUsers.contains(where: { $0.id == user.id }) {
                            self.allUsers.append(user)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Profile Photos

    func setProfilePhoto(for userId: String, imageData: Data?) {
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

    func sendFriendRequest(to userId: String) {
        guard let currentId = currentUser?.id else { return }
        let existing = friendRequests.first {
            ($0.fromUserId == currentId && $0.toUserId == userId) ||
            ($0.fromUserId == userId && $0.toUserId == currentId)
        }
        guard existing == nil else { return }
        guard !(friendships[currentId]?.contains(userId) ?? false) else { return }

        let request = FriendRequest(fromUserId: currentId, toUserId: userId)
        friendRequests.append(request)

        Task {
            do {
                _ = try await firestoreService.sendFriendRequest(from: currentId, to: userId)
            } catch {
                await MainActor.run {
                    self.friendRequests.removeAll { $0.id == request.id }
                }
                print("[DataService] Failed to send friend request: \(error)")
            }
        }
    }

    func acceptFriendRequest(_ request: FriendRequest) {
        if let idx = friendRequests.firstIndex(where: { $0.id == request.id }) {
            friendRequests[idx].status = .accepted
        }
        friendships[request.fromUserId, default: []].insert(request.toUserId)
        friendships[request.toUserId, default: []].insert(request.fromUserId)

        Task {
            do {
                try await firestoreService.acceptFriendRequest(request)
            } catch {
                print("[DataService] Failed to accept friend request: \(error)")
            }
        }
    }

    func declineFriendRequest(_ request: FriendRequest) {
        if let idx = friendRequests.firstIndex(where: { $0.id == request.id }) {
            friendRequests[idx].status = .declined
        }

        Task {
            do {
                try await firestoreService.declineFriendRequest(request.id)
            } catch {
                print("[DataService] Failed to decline friend request: \(error)")
            }
        }
    }

    func removeFriend(_ friendId: String) {
        guard let currentId = currentUser?.id else { return }
        friendships[currentId]?.remove(friendId)
        friendships[friendId]?.remove(currentId)

        Task {
            do {
                try await firestoreService.removeFriendship(userId: currentId, friendId: friendId)
            } catch {
                print("[DataService] Failed to remove friend: \(error)")
            }
        }
    }

    func friends(of userId: String) -> [User] {
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

    func isFriend(_ userId: String) -> Bool {
        guard let currentId = currentUser?.id else { return false }
        return friendships[currentId]?.contains(userId) ?? false
    }

    func hasPendingRequest(with userId: String) -> Bool {
        guard let currentId = currentUser?.id else { return false }
        return friendRequests.contains {
            $0.status == .pending &&
            (($0.fromUserId == currentId && $0.toUserId == userId) ||
             ($0.fromUserId == userId && $0.toUserId == currentId))
        }
    }

    func searchUsers(query: String) async -> [User] {
        guard let currentId = currentUser?.id else { return [] }
        guard !query.isEmpty else { return [] }
        do {
            return try await firestoreService.searchUsers(query: query, excludingUserId: currentId)
        } catch {
            print("[DataService] Search failed: \(error)")
            return []
        }
    }

    // MARK: - Weekend Status

    func setWeekendStatus(
        availability: WeekendAvailability,
        isVisible: Bool,
        shareDetails: Bool,
        courseName: String?,
        playingWith: [String],
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

        Task {
            do {
                try await firestoreService.setWeekendStatus(status)
            } catch {
                print("[DataService] Failed to set weekend status: \(error)")
            }
        }
    }

    func clearWeekendStatus() {
        guard let currentId = currentUser?.id else { return }
        weekendStatuses.removeValue(forKey: currentId)

        Task {
            do {
                try await firestoreService.clearWeekendStatus(userId: currentId)
            } catch {
                print("[DataService] Failed to clear weekend status: \(error)")
            }
        }
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

    func userName(for id: String) -> String {
        allUsers.first(where: { $0.id == id })?.displayName ?? "Unknown"
    }

    // MARK: - Messages

    func openConversation(with userId: String) {
        guard let currentId = currentUser?.id else { return }
        let convoId = FirestoreService.canonicalId(currentId, userId)
        activeConversationId = convoId

        firestoreService.startMessagesListener(conversationId: convoId) { @Sendable [weak self] messages in
            DispatchQueue.main.async {
                self?.activeConversationMessages = messages
            }
        }

        markMessagesAsRead(from: userId)
    }

    func closeConversation() {
        if let convoId = activeConversationId {
            firestoreService.removeListener(named: "messages-\(convoId)")
        }
        activeConversationId = nil
        activeConversationMessages = []
    }

    func sendMessage(to userId: String, text: String) {
        guard let currentId = currentUser?.id else { return }
        let message = Message(senderId: currentId, receiverId: userId, text: text)
        activeConversationMessages.append(message)

        Task {
            do {
                try await firestoreService.sendMessage(from: currentId, to: userId, text: text)
            } catch {
                print("[DataService] Failed to send message: \(error)")
            }
        }
    }

    func messages(with userId: String) -> [Message] {
        return activeConversationMessages
    }

    func unreadCount(from userId: String) -> Int {
        guard let currentId = currentUser?.id else { return 0 }
        let convoId = FirestoreService.canonicalId(currentId, userId)
        return conversationMetadata.first(where: { $0.id == convoId })?.unreadCount ?? 0
    }

    func markMessagesAsRead(from userId: String) {
        guard let currentId = currentUser?.id else { return }
        let convoId = FirestoreService.canonicalId(currentId, userId)

        // Update local metadata
        if let idx = conversationMetadata.firstIndex(where: { $0.id == convoId }) {
            conversationMetadata[idx].unreadCount = 0
        }

        Task {
            do {
                try await firestoreService.markMessagesAsRead(conversationId: convoId, userId: currentId)
            } catch {
                print("[DataService] Failed to mark messages as read: \(error)")
            }
        }
    }
}
