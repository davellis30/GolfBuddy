import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // System permission status
                    systemPermissionCard

                    // Notification type toggles
                    if notificationService.permissionStatus == .authorized {
                        togglesCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var systemPermissionCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: notificationService.permissionStatus == .authorized ? "bell.badge.fill" : "bell.slash.fill")
                    .font(.system(size: 24))
                    .foregroundColor(notificationService.permissionStatus == .authorized ? AppTheme.accentGreen : AppTheme.mutedText)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Push Notifications")
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundColor(AppTheme.darkText)
                    Text(notificationService.permissionStatus == .authorized ? "Enabled at the system level" : "Disabled in system settings")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                }

                Spacer()

                if notificationService.permissionStatus == .authorized {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentGreen)
                        .font(.system(size: 22))
                } else if notificationService.permissionStatus == .denied {
                    Button("Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(AppTheme.captionFont.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppTheme.accentGreen))
                } else {
                    Button("Enable") {
                        Task { await notificationService.requestPermission() }
                    }
                    .font(AppTheme.captionFont.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppTheme.accentGreen))
                }
            }
        }
        .cardStyle()
    }

    private var togglesCard: some View {
        VStack(spacing: 0) {
            Text("Notification Types")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            notificationToggle(
                icon: "person.badge.plus",
                title: "Friend Requests",
                subtitle: "When someone sends you a request",
                isOn: Binding(
                    get: { dataService.notificationPreferences.friendRequests },
                    set: { newValue in
                        var prefs = dataService.notificationPreferences
                        prefs.friendRequests = newValue
                        dataService.updateNotificationPreferences(prefs)
                    }
                )
            )

            Divider().padding(.vertical, 8)

            notificationToggle(
                icon: "message.fill",
                title: "Messages",
                subtitle: "When a friend sends you a message",
                isOn: Binding(
                    get: { dataService.notificationPreferences.messages },
                    set: { newValue in
                        var prefs = dataService.notificationPreferences
                        prefs.messages = newValue
                        dataService.updateNotificationPreferences(prefs)
                    }
                )
            )

            Divider().padding(.vertical, 8)

            notificationToggle(
                icon: "calendar.badge.clock",
                title: "Status Updates",
                subtitle: "When a friend updates their weekend status",
                isOn: Binding(
                    get: { dataService.notificationPreferences.statusChanges },
                    set: { newValue in
                        var prefs = dataService.notificationPreferences
                        prefs.statusChanges = newValue
                        dataService.updateNotificationPreferences(prefs)
                    }
                )
            )
        }
        .cardStyle()
    }

    private func notificationToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.darkText)
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.accentGreen)
        }
    }
}
