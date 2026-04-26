import Foundation
import UserNotifications
import UIKit

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    static let statusCategoryIdentifier = "STATUS_REMINDER"
    static let actionLooking = "ACTION_LOOKING_TO_PLAY"
    static let actionPlaying = "ACTION_ALREADY_PLAYING"
    static let actionSeeking = "ACTION_SEEKING_ADDITIONAL"
    static let actionNotThisWeekend = "ACTION_NOT_THIS_WEEKEND"

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?

    private let center = UNUserNotificationCenter.current()

    private init() {
        registerNotificationCategories()
        Task { await checkPermissionStatus() }
    }

    // MARK: - Categories & Actions

    private func registerNotificationCategories() {
        let lookingAction = UNNotificationAction(
            identifier: Self.actionLooking,
            title: "Looking to Play",
            options: []
        )
        let playingAction = UNNotificationAction(
            identifier: Self.actionPlaying,
            title: "Already Playing",
            options: []
        )
        let seekingAction = UNNotificationAction(
            identifier: Self.actionSeeking,
            title: "Need 1 More",
            options: []
        )
        let notThisWeekendAction = UNNotificationAction(
            identifier: Self.actionNotThisWeekend,
            title: "Not This Weekend",
            options: []
        )

        let statusCategory = UNNotificationCategory(
            identifier: Self.statusCategoryIdentifier,
            actions: [lookingAction, playingAction, seekingAction, notThisWeekendAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([statusCategory])
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { permissionStatus = granted ? .authorized : .denied }
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                scheduleWeeklyStatusReminder()
            }
            return granted
        } catch {
            print("[NotificationService] Permission request failed: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run { permissionStatus = settings.authorizationStatus }
    }

    // MARK: - Local Notifications

    func scheduleWeeklyStatusReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Set Your Weekend Status"
        content.body = "Let your friends know your golf plans for this weekend!"
        content.sound = .default
        content.categoryIdentifier = Self.statusCategoryIdentifier

        var dateComponents = DateComponents()
        dateComponents.weekday = 5 // Thursday
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-status-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to schedule weekly reminder: \(error)")
            }
        }
    }

    func notifyFriendStatusUpdate(friendName: String, availability: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(friendName) Updated Their Status"
        content.body = "They are \(availability) this weekend"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "friend-status-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to send friend status notification: \(error)")
            }
        }
    }

    func cancelWeeklyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-status-reminder"])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Action Handling

    func handleNotificationAction(_ actionIdentifier: String) {
        let availability: WeekendAvailability? = switch actionIdentifier {
        case Self.actionLooking: .lookingToPlay
        case Self.actionPlaying: .alreadyPlaying
        case Self.actionSeeking: .seekingAdditional
        default: nil
        }

        Task { @MainActor in
            if actionIdentifier == Self.actionNotThisWeekend {
                DataService.shared.clearWeekendStatus()
            } else if let availability {
                DataService.shared.setWeekendStatus(
                    availability: availability,
                    isVisible: true,
                    shareDetails: false,
                    courseName: nil,
                    playingWith: []
                )
            }
        }
    }

    // MARK: - Remote Notification Stubs

    func registerDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        print("[NotificationService] APNs device token: \(tokenString)")
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        print("[NotificationService] Received remote notification: \(userInfo)")
    }
}
