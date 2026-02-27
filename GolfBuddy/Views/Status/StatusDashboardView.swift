import SwiftUI

struct StatusDashboardView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showSetStatus = false
    @State private var showCreateInvite = false

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

                        // Open Invites section
                        VStack(spacing: 10) {
                            HStack {
                                Text("OPEN INVITES")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.mutedText)
                                    .tracking(1)
                                Spacer()
                                Button {
                                    showCreateInvite = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppTheme.accentGreen)
                                }
                            }

                            let invites = dataService.visibleOpenInvites()
                            if invites.isEmpty {
                                Text("No open invites yet")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.mutedText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(Array(invites.enumerated()), id: \.element.id) { index, invite in
                                        NavigationLink(destination: InviteDetailView(inviteId: invite.id)) {
                                            OpenInviteCard(invite: invite)
                                        }
                                        .buttonStyle(.plain)
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .offset(y: 10)),
                                            removal: .opacity
                                        ))
                                        .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(Double(index) * 0.06), value: invites.count)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Friends statuses
                        let friendStatuses = dataService.visibleFriendStatuses()
                        let grouped = groupedFriendStatuses(friendStatuses)

                        if !friendStatuses.isEmpty {
                            LazyVStack(spacing: 10) {
                                ForEach(grouped, id: \.category) { section in
                                    SectionHeader(title: section.category.rawValue)
                                        .padding(.horizontal, 20)
                                        .padding(.top, section.category == grouped.first?.category ? 0 : 6)

                                    ForEach(section.friends, id: \.0.id) { friend, status in
                                        NavigationLink(destination: ConversationView(friend: friend)) {
                                            FriendStatusCard(friend: friend, status: status)
                                        }
                                        .buttonStyle(.plain)
                                    }
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
            .sheet(isPresented: $showCreateInvite) {
                CreateInviteView()
            }
        }
    }

    private struct StatusSection {
        let category: WeekendAvailability
        let friends: [(User, WeekendStatus)]
    }

    private func groupedFriendStatuses(_ statuses: [(User, WeekendStatus)]) -> [StatusSection] {
        let myAvailability: WeekendAvailability? = {
            guard let userId = dataService.currentUser?.id else { return nil }
            return dataService.weekendStatuses[userId]?.availability
        }()

        // Determine category ordering based on the current user's status
        let order: [WeekendAvailability] = {
            switch myAvailability {
            case .lookingToPlay:
                return [.seekingAdditional, .lookingToPlay, .alreadyPlaying]
            case .seekingAdditional:
                return [.lookingToPlay, .seekingAdditional, .alreadyPlaying]
            case .alreadyPlaying, .none:
                return [.lookingToPlay, .seekingAdditional, .alreadyPlaying]
            }
        }()

        // Group statuses by availability
        let grouped = Dictionary(grouping: statuses) { $0.1.availability }

        // Build sections in the determined order, skipping empty categories
        return order.compactMap { category in
            guard let friends = grouped[category], !friends.isEmpty else { return nil }
            return StatusSection(category: category, friends: friends)
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

                if !status.timeSlots.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(status.timeSlots, id: \.self) { slot in
                            let isPreferred = status.preferredTimeSlot == slot
                            HStack(spacing: 4) {
                                if isPreferred {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                }
                                Text(slot.label)
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(isPreferred ? AppTheme.gold : AppTheme.accentGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(isPreferred ? AppTheme.gold.opacity(0.15) : AppTheme.accentGreen.opacity(0.12))
                            )
                        }
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
                AvatarView(userId: friend.id, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundColor(AppTheme.darkText)

                    if let tagline = friend.statusTagline, !tagline.isEmpty {
                        Text(tagline)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(friend.themeColor.color)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: status.availability.icon)
                            .font(.system(size: 11))
                        Text(status.availability.rawValue)
                            .font(AppTheme.captionFont)
                    }
                    .foregroundColor(status.availability.color)
                }

                Spacer()

                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accentGreen)
            }

            if !status.timeSlots.isEmpty {
                HStack(spacing: 4) {
                    ForEach(status.timeSlots, id: \.self) { slot in
                        let isPreferred = status.preferredTimeSlot == slot
                        HStack(spacing: 3) {
                            if isPreferred {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                            }
                            Text(slot.label)
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(isPreferred ? AppTheme.gold : status.availability.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isPreferred ? AppTheme.gold.opacity(0.15) : status.availability.color.opacity(0.12))
                        )
                    }
                    Spacer()
                }
                .padding(.leading, 56)
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
        .overlay(
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(friend.themeColor.color)
                    .frame(width: 4)
                Spacer()
            }
            .padding(.vertical, 8)
        )
    }
}

struct OpenInviteCard: View {
    @EnvironmentObject var dataService: DataService
    let invite: OpenInvite

    private var isCreator: Bool {
        dataService.currentUser?.id == invite.creatorId
    }

    private var pendingCount: Int {
        invite.joinRequests.filter { $0.status == .pending }.count
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                AvatarView(userId: invite.creatorId, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isCreator ? "Your Invite" : dataService.userName(for: invite.creatorId))
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundColor(AppTheme.darkText)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                        Text("\(invite.approvedPlayerIds.count)/\(invite.groupSize)")
                            .font(AppTheme.captionFont)
                    }
                    .foregroundColor(invite.isFull ? AppTheme.mutedText : AppTheme.accentGreen)
                }

                Spacer()

                if isCreator && pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(AppTheme.statusSeeking))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.mutedText)
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.accentGreen)
                    Text(invite.courseName)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.darkText)
                }

                Text(invite.timeSlot.label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.accentGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentGreen.opacity(0.12))
                    )

                Spacer()
            }
            .padding(.leading, 56)
        }
        .cardStyle()
    }
}
