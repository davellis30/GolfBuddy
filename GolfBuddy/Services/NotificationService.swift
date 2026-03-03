import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func notifyInvitedToPlay(by inviterName: String, courseName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "You've been invited to play!"
        if let course = courseName {
            content.body = "\(inviterName) added you to their weekend round at \(course)."
        } else {
            content.body = "\(inviterName) added you to their weekend round."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "invite-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func notifyFriendSeekingPlayer(friendName: String, courseName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "New Open Invite"
        if let course = courseName {
            content.body = "\(friendName) is looking for an additional player at \(course) this weekend."
        } else {
            content.body = "\(friendName) is looking for an additional player this weekend."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "open-invite-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
