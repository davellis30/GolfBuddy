import Foundation
import UserNotifications
import UIKit

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await checkPermissionStatus() }
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

    // MARK: - Remote Notification Stubs

    func registerDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        print("[NotificationService] APNs device token: \(tokenString)")
        // TODO: Send token to backend when available
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        print("[NotificationService] Received remote notification: \(userInfo)")
        // TODO: Parse and handle remote notification payload from backend
    }
}
