import Foundation
import Combine
import UIKit
import AuthenticationServices
import CoreLocation
import FirebaseStorage

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
    @Published var notificationPreferences: NotificationPreferences = .defaults
    @Published var openInvites: [OpenInvite] = []
    @Published var myCalendarEntries: [String: WeekendAvailability] = [:]
    @Published var friendCalendarCache: [String: [String: WeekendAvailability]] = [:]
    @Published var nearbyCourses: [Course] = CourseService.chicagoAreaCourses
    @Published var isEmailVerified: Bool = false
    @Published var showVerificationBanner: Bool = false

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
        try? await FirebaseAuthService.shared.sendEmailVerification()
        await MainActor.run {
            self.allUsers.append(user)
            self.currentUser = user
            self.friendships[user.id] = []
            self.isEmailVerified = false
            self.showVerificationBanner = true
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

    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        let user = try await FirebaseAuthService.shared.signInWithGoogle(presenting: viewController)
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
        if let userId = currentUser?.id {
            NotificationService.shared.clearFCMToken(userId: userId)
        }
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
        openInvites = []
        myCalendarEntries = [:]
        friendCalendarCache = [:]
        messages = []
        profilePhotos = [:]
        conversationMetadata = []
        activeConversationMessages = []
        isEmailVerified = false
        showVerificationBanner = false
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

    // MARK: - Email Verification

    func sendEmailVerification() {
        Task {
            try? await FirebaseAuthService.shared.sendEmailVerification()
        }
    }

    func checkEmailVerification() {
        Task {
            try? await FirebaseAuthService.shared.reloadUser()
            let verified = FirebaseAuthService.shared.isEmailVerified
            await MainActor.run {
                self.isEmailVerified = verified
                if verified {
                    self.showVerificationBanner = false
                }
            }
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
        loadProfilePhoto(for: user.id)
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

        NotificationService.shared.fetchAndStoreFCMToken(userId: userId)
        await loadNotificationPreferences(userId: userId)

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

        firestoreService.startOpenInvitesListener(userId: userId) { @Sendable [weak self] invites in
            DispatchQueue.main.async {
                self?.openInvites = invites
                let userIds = Set(
                    invites.flatMap { invite in
                        [invite.creatorId] + invite.approvedPlayerIds + invite.joinRequests.map { $0.userId }
                    }
                )
                self?.fetchMissingUserProfiles(friendIds: userIds)
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

    private let storageRef = Storage.storage().reference()

    func uploadProfilePhoto(for userId: String, imageData: Data) async throws {
        guard let processed = processProfileImage(imageData) else { return }

        // Update local cache immediately
        await MainActor.run { profilePhotos[userId] = processed }

        // Upload to Firebase Storage
        let photoRef = storageRef.child("profilePhotos/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await photoRef.putDataAsync(processed, metadata: metadata)
        let downloadUrl = try await photoRef.downloadURL()
        let urlString = downloadUrl.absoluteString

        // Save URL to Firestore and update local user
        try await FirebaseAuthService.shared.updateProfilePhotoUrl(firebaseUserId: userId, url: urlString)
        await MainActor.run {
            self.currentUser?.profilePhotoUrl = urlString
            if let idx = self.allUsers.firstIndex(where: { $0.id == userId }) {
                self.allUsers[idx].profilePhotoUrl = urlString
            }
        }
    }

    func removeProfilePhoto(for userId: String) async throws {
        await MainActor.run { profilePhotos.removeValue(forKey: userId) }

        let photoRef = storageRef.child("profilePhotos/\(userId).jpg")
        try? await photoRef.delete()

        try await FirebaseAuthService.shared.updateProfilePhotoUrl(firebaseUserId: userId, url: nil)
        await MainActor.run {
            self.currentUser?.profilePhotoUrl = nil
            if let idx = self.allUsers.firstIndex(where: { $0.id == userId }) {
                self.allUsers[idx].profilePhotoUrl = nil
            }
        }
    }

    func loadProfilePhoto(for userId: String) {
        guard profilePhotos[userId] == nil else { return }
        guard let user = allUsers.first(where: { $0.id == userId }),
              let urlString = user.profilePhotoUrl,
              let url = URL(string: urlString) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.profilePhotos[userId] = data
                }
            } catch {
                print("[DataService] Failed to load profile photo for \(userId): \(error)")
            }
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

    func findContactsOnApp() async -> [User] {
        guard let currentId = currentUser?.id else { return [] }
        let status = ContactsService.shared.accessStatus
        guard status == .authorized || status == .limited else { return [] }

        let contacts = ContactsService.shared.fetchContacts()
        let emails = Array(Set(
            contacts.flatMap { $0.emailAddresses.map { ($0.value as String).lowercased() } }
        ))
        guard !emails.isEmpty else { return [] }

        do {
            let users = try await firestoreService.fetchUsersByEmails(emails)
            let friendIds = friendships[currentId] ?? []
            return users.filter { $0.id != currentId && !friendIds.contains($0.id) }
        } catch {
            print("[DataService] Contact match failed: \(error)")
            return []
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

    // MARK: - Open Invites

    func createOpenInvite(courseName: String, timeSlot: DayTimeSlot, groupSize: Int) {
        guard let currentId = currentUser?.id else { return }
        let friendIds = Array(friendships[currentId] ?? [])
        let visibleTo = [currentId] + friendIds

        let invite = OpenInvite(
            creatorId: currentId,
            courseName: courseName,
            timeSlot: timeSlot,
            groupSize: groupSize,
            visibleToFriendIds: visibleTo
        )
        openInvites.append(invite)

        Task {
            do {
                try await firestoreService.createOpenInvite(invite)
            } catch {
                await MainActor.run {
                    self.openInvites.removeAll { $0.id == invite.id }
                }
                print("[DataService] Failed to create open invite: \(error)")
            }
        }
    }

    func requestToJoinInvite(_ invite: OpenInvite) {
        guard let currentId = currentUser?.id,
              let idx = openInvites.firstIndex(where: { $0.id == invite.id }) else { return }
        let liveInvite = openInvites[idx]
        let alreadyRequested = liveInvite.joinRequests.contains { $0.userId == currentId }
        let alreadyApproved = liveInvite.approvedPlayerIds.contains(currentId)
        let activeRequestCount = liveInvite.joinRequests.filter { $0.status == .pending }.count
        guard !alreadyRequested && !alreadyApproved && activeRequestCount < 3 else { return }

        let request = JoinRequest(userId: currentId)
        openInvites[idx].joinRequests.append(request)

        Task {
            do {
                try await firestoreService.requestToJoinInvite(inviteId: invite.id, joinRequest: request)
            } catch {
                await MainActor.run {
                    if let idx = self.openInvites.firstIndex(where: { $0.id == invite.id }) {
                        self.openInvites[idx].joinRequests.removeAll { $0.id == request.id }
                    }
                }
                print("[DataService] Failed to request to join invite: \(error)")
            }
        }
    }

    func approveJoinRequest(invite: OpenInvite, request: JoinRequest) {
        guard let idx = openInvites.firstIndex(where: { $0.id == invite.id }),
              openInvites[idx].status == .open,
              openInvites[idx].spotsRemaining > 0 else { return }

        if let rIdx = openInvites[idx].joinRequests.firstIndex(where: { $0.id == request.id }) {
            openInvites[idx].joinRequests[rIdx].status = .approved
        }
        openInvites[idx].approvedPlayerIds.append(request.userId)
        if openInvites[idx].isFull {
            openInvites[idx].status = .full
        }

        Task {
            do {
                try await firestoreService.approveJoinRequest(inviteId: invite.id, requestId: request.id, userId: request.userId)
            } catch {
                print("[DataService] Failed to approve join request: \(error)")
            }
        }
    }

    func declineJoinRequest(invite: OpenInvite, request: JoinRequest) {
        if let idx = openInvites.firstIndex(where: { $0.id == invite.id }) {
            if let rIdx = openInvites[idx].joinRequests.firstIndex(where: { $0.id == request.id }) {
                openInvites[idx].joinRequests[rIdx].status = .declined
            }
        }

        Task {
            do {
                try await firestoreService.declineJoinRequest(inviteId: invite.id, requestId: request.id)
            } catch {
                print("[DataService] Failed to decline join request: \(error)")
            }
        }
    }

    func cancelOpenInvite(_ invite: OpenInvite) {
        if let idx = openInvites.firstIndex(where: { $0.id == invite.id }) {
            openInvites[idx].status = .cancelled
        }

        Task {
            do {
                try await firestoreService.cancelOpenInvite(inviteId: invite.id)
            } catch {
                print("[DataService] Failed to cancel open invite: \(error)")
            }
        }
    }

    func visibleOpenInvites() -> [OpenInvite] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return openInvites.filter { $0.status != .cancelled && $0.weekendDate >= startOfToday }
    }

    // MARK: - Calendar

    func loadMyCalendar() {
        guard let userId = currentUser?.id else { return }
        Task {
            do {
                if let entry = try await firestoreService.fetchCalendarEntries(userId: userId) {
                    await MainActor.run {
                        self.myCalendarEntries = entry.entries
                    }
                }
            } catch {
                print("[DataService] Failed to load calendar: \(error)")
            }
        }
    }

    func setCalendarEntry(date: Date, availability: WeekendAvailability) {
        guard let userId = currentUser?.id else { return }
        let key = CalendarEntry.dateKey(from: date)
        myCalendarEntries[key] = availability

        Task {
            do {
                try await firestoreService.setCalendarEntry(userId: userId, dateKey: key, availability: availability)
            } catch {
                print("[DataService] Failed to set calendar entry: \(error)")
            }
        }
    }

    func clearCalendarEntry(date: Date) {
        guard let userId = currentUser?.id else { return }
        let key = CalendarEntry.dateKey(from: date)
        myCalendarEntries.removeValue(forKey: key)

        Task {
            do {
                try await firestoreService.clearCalendarEntry(userId: userId, dateKey: key)
            } catch {
                print("[DataService] Failed to clear calendar entry: \(error)")
            }
        }
    }

    func fetchFriendCalendar(userId: String) async -> [String: WeekendAvailability] {
        if let cached = friendCalendarCache[userId] {
            return cached
        }
        do {
            if let entry = try await firestoreService.fetchCalendarEntries(userId: userId) {
                await MainActor.run {
                    self.friendCalendarCache[userId] = entry.entries
                }
                return entry.entries
            }
        } catch {
            print("[DataService] Failed to fetch friend calendar: \(error)")
        }
        return [:]
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

    // MARK: - Notification Preferences

    private func loadNotificationPreferences(userId: String) async {
        do {
            let prefs = try await firestoreService.fetchNotificationPreferences(userId: userId)
            await MainActor.run { self.notificationPreferences = prefs }
        } catch {
            print("[DataService] Failed to load notification preferences: \(error)")
        }
    }

    func updateNotificationPreferences(_ prefs: NotificationPreferences) {
        guard let userId = currentUser?.id else { return }
        notificationPreferences = prefs
        Task {
            do {
                try await firestoreService.updateNotificationPreferences(userId: userId, prefs: prefs)
            } catch {
                print("[DataService] Failed to update notification preferences: \(error)")
            }
        }
    }
}
