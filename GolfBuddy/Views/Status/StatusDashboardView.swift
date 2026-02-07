import SwiftUI

struct StatusDashboardView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showSetStatus = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Weekend header
                        VStack(spacing: 4) {
                            Text("This Weekend")
                                .font(AppTheme.titleFont)
                                .foregroundColor(AppTheme.primaryGreen)
                            Text(WeekendStatus.weekendLabel())
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.mutedText)
                        }
                        .padding(.top, 8)

                        // My status card
                        myStatusCard
                            .padding(.horizontal, 20)

                        // Friends statuses
                        let friendStatuses = dataService.visibleFriendStatuses()

                        if !friendStatuses.isEmpty {
                            SectionHeader(title: "Friends' Plans")
                                .padding(.horizontal, 20)

                            LazyVStack(spacing: 10) {
                                ForEach(friendStatuses, id: \.0.id) { friend, status in
                                    FriendStatusCard(friend: friend, status: status)
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppTheme.mutedText)
                                Text("No friends have shared their weekend plans yet")
                                    .font(AppTheme.bodyFont)
                                    .foregroundColor(AppTheme.mutedText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 24)
                            .padding(.horizontal, 40)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Weekend")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSetStatus) {
                SetStatusView()
            }
        }
    }

    @ViewBuilder
    private var myStatusCard: some View {
        if let userId = dataService.currentUser?.id,
           let status = dataService.weekendStatuses[userId] {
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: status.availability.icon)
                        .font(.system(size: 22))
                        .foregroundColor(status.availability.color)
                    Text(status.availability.rawValue)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.darkText)
                    Spacer()
                }

                if let course = status.courseName, status.shareDetails {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppTheme.accentGreen)
                        Text(course)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.darkText)
                        Spacer()
                    }
                }

                if status.shareDetails && !status.playingWith.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(AppTheme.accentGreen)
                        Text("With: \(status.playingWith.map { dataService.userName(for: $0) }.joined(separator: ", "))")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.darkText)
                        Spacer()
                    }
                }

                HStack(spacing: 16) {
                    Label(
                        status.isVisible ? "Visible to friends" : "Hidden from friends",
                        systemImage: status.isVisible ? "eye.fill" : "eye.slash.fill"
                    )
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)

                    Spacer()

                    Button("Update") { showSetStatus = true }
                        .font(AppTheme.captionFont.weight(.semibold))
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
            .cardStyle()
        } else {
            VStack(spacing: 14) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.accentGreen)

                Text("Set your weekend status")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.darkText)

                Text("Let your friends know if you're available to play this weekend.")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.mutedText)
                    .multilineTextAlignment(.center)

                Button("Set Status") { showSetStatus = true }
                    .buttonStyle(GreenButtonStyle())
            }
            .cardStyle()
        }
    }
}

struct FriendStatusCard: View {
    @EnvironmentObject var dataService: DataService
    let friend: User
    let status: WeekendStatus

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(status.availability.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(friend.avatarInitials)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(status.availability.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundColor(AppTheme.darkText)

                    HStack(spacing: 4) {
                        Image(systemName: status.availability.icon)
                            .font(.system(size: 11))
                        Text(status.availability.rawValue)
                            .font(AppTheme.captionFont)
                    }
                    .foregroundColor(status.availability.color)
                }

                Spacer()
            }

            if status.shareDetails {
                if let course = status.courseName {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.accentGreen)
                        Text(course)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.darkText)
                        Spacer()
                    }
                    .padding(.leading, 56)
                }

                if !status.playingWith.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.accentGreen)
                        Text("With: \(status.playingWith.map { dataService.userName(for: $0) }.joined(separator: ", "))")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.darkText)
                        Spacer()
                    }
                    .padding(.leading, 56)
                }
            }
        }
        .cardStyle()
    }
}
