import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                if let user = dataService.currentUser {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Avatar + Name
                            VStack(spacing: 14) {
                                AvatarView(userId: user.id, size: 100)

                                Text(user.displayName)
                                    .font(AppTheme.titleFont)
                                    .foregroundColor(AppTheme.darkText)

                                Text("@\(user.username)")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.mutedText)
                            }
                            .padding(.top, 20)

                            // Stats Card
                            VStack(spacing: 16) {
                                ProfileStatRow(label: "Email", value: user.email, icon: "envelope.fill")
                                Divider()
                                ProfileStatRow(
                                    label: "Handicap",
                                    value: user.handicap.map { String(format: "%.1f", $0) } ?? "Not set",
                                    icon: "number"
                                )
                                Divider()
                                ProfileStatRow(
                                    label: "Home Course",
                                    value: user.homeCourse ?? "Not set",
                                    icon: "mappin.circle.fill"
                                )
                                Divider()
                                ProfileStatRow(
                                    label: "Friends",
                                    value: "\(dataService.friends(of: user.id).count)",
                                    icon: "person.2.fill"
                                )
                                Divider()
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(AppTheme.accentGreen)
                                        .frame(width: 24)
                                    Text("Notifications")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.mutedText)
                                    Spacer()
                                    if notificationService.permissionStatus == .authorized {
                                        Text("Enabled")
                                            .font(AppTheme.bodyFont.weight(.medium))
                                            .foregroundColor(AppTheme.accentGreen)
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
                            .padding(.horizontal, 20)

                            // Weekend status summary
                            if let status = dataService.weekendStatuses[user.id] {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("This Weekend")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.mutedText)

                                    HStack {
                                        Image(systemName: status.availability.icon)
                                            .foregroundColor(status.availability.color)
                                        Text(status.availability.rawValue)
                                            .font(AppTheme.bodyFont.weight(.semibold))
                                            .foregroundColor(AppTheme.darkText)
                                        Spacer()
                                        if !status.isVisible {
                                            Label("Hidden", systemImage: "eye.slash.fill")
                                                .font(AppTheme.captionFont)
                                                .foregroundColor(AppTheme.mutedText)
                                        }
                                    }
                                }
                                .cardStyle()
                                .padding(.horizontal, 20)
                            }

                            // Edit + Sign Out
                            VStack(spacing: 12) {
                                Button("Edit Profile") { showEditSheet = true }
                                    .buttonStyle(GreenButtonStyle())

                                Button("Sign Out") { dataService.signOut() }
                                    .buttonStyle(OutlineButtonStyle())

                                Button(action: { showDeleteConfirmation = true }) {
                                    if isDeleting {
                                        ProgressView()
                                            .tint(.red)
                                    } else {
                                        Text("Delete Account")
                                            .font(AppTheme.captionFont.weight(.semibold))
                                            .foregroundColor(.red)
                                    }
                                }
                                .disabled(isDeleting)
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)

                            Spacer().frame(height: 40)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditSheet) {
                EditProfileView()
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    isDeleting = true
                    Task {
                        do {
                            try await dataService.deleteAccount()
                        } catch {
                            await MainActor.run { isDeleting = false }
                            print("[ProfileView] Delete account failed: \(error)")
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account, friends, messages, and all data. This cannot be undone.")
            }
        }
    }
}

struct ProfileStatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentGreen)
                .frame(width: 24)
            Text(label)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.mutedText)
            Spacer()
            Text(value)
                .font(AppTheme.bodyFont.weight(.medium))
                .foregroundColor(AppTheme.darkText)
                .lineLimit(1)
        }
    }
}
