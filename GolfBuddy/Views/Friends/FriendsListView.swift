import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showAddFriend = false
    @State private var showRequests = false
    @State private var filterByHandicap = false
    @State private var handicapMin: Double = 0
    @State private var handicapMax: Double = 36

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Pending requests banner
                        let pending = dataService.pendingRequestsForCurrentUser()
                        if !pending.isEmpty {
                            Button(action: { showRequests = true }) {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.white)
                                    Text("\(pending.count) Pending Request\(pending.count == 1 ? "" : "s")")
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.statusSeeking)
                                )
                            }
                            .padding(.horizontal, 20)
                        }

                        // Handicap filter
                        if filterByHandicap {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Handicap Range")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.darkText)
                                    Spacer()
                                    Text("\(Int(handicapMin)) – \(Int(handicapMax))")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.accentGreen)
                                }

                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Min")
                                            .font(AppTheme.captionFont)
                                            .foregroundColor(AppTheme.mutedText)
                                            .frame(width: 30)
                                        Slider(value: $handicapMin, in: 0...36, step: 1) {
                                            Text("Min")
                                        }
                                        .tint(AppTheme.accentGreen)
                                        .onChange(of: handicapMin) { _, newVal in
                                            if newVal > handicapMax {
                                                handicapMax = newVal
                                            }
                                        }
                                    }

                                    HStack {
                                        Text("Max")
                                            .font(AppTheme.captionFont)
                                            .foregroundColor(AppTheme.mutedText)
                                            .frame(width: 30)
                                        Slider(value: $handicapMax, in: 0...36, step: 1) {
                                            Text("Max")
                                        }
                                        .tint(AppTheme.accentGreen)
                                        .onChange(of: handicapMax) { _, newVal in
                                            if newVal < handicapMin {
                                                handicapMin = newVal
                                            }
                                        }
                                    }
                                }

                                let allFriends = allFriendsUnfiltered
                                let filtered = currentUserFriends
                                if allFriends.count != filtered.count {
                                    Text("Showing \(filtered.count) of \(allFriends.count) friends")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.mutedText)
                                }
                            }
                            .cardStyle()
                            .padding(.horizontal, 20)
                        }

                        // Friends list
                        let myFriends = currentUserFriends
                        if myFriends.isEmpty {
                            VStack(spacing: 16) {
                                if filterByHandicap && !allFriendsUnfiltered.isEmpty {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppTheme.mutedText)
                                    Text("No matches")
                                        .font(AppTheme.headlineFont)
                                        .foregroundColor(AppTheme.darkText)
                                    Text("No friends in the \(Int(handicapMin))–\(Int(handicapMax)) handicap range.")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.mutedText)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Image(systemName: "person.2.slash")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppTheme.mutedText)
                                    Text("No friends yet")
                                        .font(AppTheme.headlineFont)
                                        .foregroundColor(AppTheme.darkText)
                                    Text("Add friends to see their weekend golf plans!")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.mutedText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(myFriends) { friend in
                                    NavigationLink(destination: FriendProfileView(user: friend)) {
                                        FriendRow(
                                            friend: friend,
                                            status: dataService.weekendStatuses[friend.id],
                                            unreadCount: dataService.unreadCount(from: friend.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation { filterByHandicap.toggle() }
                        }) {
                            Image(systemName: filterByHandicap ? "slider.horizontal.3" : "slider.horizontal.3")
                                .foregroundColor(filterByHandicap ? AppTheme.primaryGreen : AppTheme.accentGreen)
                                .symbolVariant(filterByHandicap ? .fill : .none)
                        }

                        Button(action: { showAddFriend = true }) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(AppTheme.accentGreen)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !dataService.pendingRequestsForCurrentUser().isEmpty {
                        Button(action: { showRequests = true }) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.accentGreen)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
            }
            .sheet(isPresented: $showRequests) {
                FriendRequestsView()
            }
        }
    }

    private var allFriendsUnfiltered: [User] {
        guard let userId = dataService.currentUser?.id else { return [] }
        return dataService.friends(of: userId)
    }

    private var currentUserFriends: [User] {
        let all = allFriendsUnfiltered
        guard filterByHandicap else { return all }
        return all.filter { friend in
            guard let handicap = friend.handicap else { return false }
            return handicap >= handicapMin && handicap <= handicapMax
        }
    }
}

struct FriendRow: View {
    let friend: User
    let status: WeekendStatus?
    var unreadCount: Int = 0

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarView(userId: friend.id, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.displayName)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundColor(AppTheme.darkText)

                Text("@\(friend.username)")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)

                if let tagline = friend.statusTagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(friend.themeColor.color)
                        .lineLimit(1)
                }

                if let handicap = friend.handicap {
                    Text("Hdcp \(handicap, specifier: "%.1f")")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.accentGreen)
                } else {
                    Text("No handicap")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText.opacity(0.6))
                }
            }

            Spacer()

            // Message button
            NavigationLink(destination: ConversationView(friend: friend)) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.accentGreen)
                        .frame(width: 36, height: 36)

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(AppTheme.statusSeeking))
                            .offset(x: 4, y: -4)
                    }
                }
            }

            // Status badge
            if let status = status, status.isVisible {
                HStack(spacing: 4) {
                    Image(systemName: status.availability.icon)
                        .font(.system(size: 11))
                    Text(status.availability.shortLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(status.availability.color)
                )
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
