import SwiftUI

struct FriendProfileView: View {
    @EnvironmentObject var dataService: DataService
    let user: User

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

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

                        if let tagline = user.statusTagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(user.themeColor.color)
                        }
                    }
                    .padding(.top, 20)

                    // Stats Card
                    VStack(spacing: 16) {
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
                    }
                    .cardStyle()
                    .padding(.horizontal, 20)

                    // Weekend status
                    if let status = dataService.weekendStatuses[user.id], status.isVisible {
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
                            }

                            if status.shareDetails {
                                if let course = status.courseName {
                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(AppTheme.accentGreen)
                                            .frame(width: 20)
                                        Text(course)
                                            .font(AppTheme.captionFont)
                                            .foregroundColor(AppTheme.darkText)
                                    }
                                }

                                if !status.timeSlots.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(AppTheme.accentGreen)
                                            .frame(width: 20)
                                        Text(status.formattedTimeSlots)
                                            .font(AppTheme.captionFont)
                                            .foregroundColor(AppTheme.darkText)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)
                    }

                    // Calendar button
                    NavigationLink(destination: FriendCalendarView(friend: user)) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("View Calendar")
                        }
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .padding(.horizontal, 20)

                    // Message button
                    NavigationLink(destination: ConversationView(friend: user)) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Message")
                        }
                    }
                    .buttonStyle(GreenButtonStyle())
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
