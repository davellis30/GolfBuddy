import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showAddFriend = false
    @State private var showRequests = false

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

                        // Friends list
                        let myFriends = currentUserFriends
                        if myFriends.isEmpty {
                            VStack(spacing: 16) {
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
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(myFriends) { friend in
                                    FriendRow(
                                        friend: friend,
                                        status: dataService.weekendStatuses[friend.id],
                                        unreadCount: dataService.unreadCount(from: friend.id)
                                    )
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
                    Button(action: { showAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(AppTheme.accentGreen)
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

    private var currentUserFriends: [User] {
        guard let userId = dataService.currentUser?.id else { return [] }
        return dataService.friends(of: userId)
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
    }
}
