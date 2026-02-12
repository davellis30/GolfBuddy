import SwiftUI

struct MessagesListView: View {
    @EnvironmentObject var dataService: DataService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.mutedText)
                        Text("No messages yet")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.darkText)
                        Text("Message a friend to start planning your next round!")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(conversations, id: \.friend.id) { convo in
                                NavigationLink(destination: ConversationView(friend: convo.friend)) {
                                    ConversationRow(
                                        friend: convo.friend,
                                        meta: convo.lastMessage,
                                        unreadCount: convo.unreadCount
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var conversations: [(friend: User, lastMessage: ConversationMeta, unreadCount: Int)] {
        guard let currentId = dataService.currentUser?.id else { return [] }

        return dataService.conversationMetadata.compactMap { meta in
            guard let partnerId = meta.partnerId(currentUserId: currentId),
                  let friend = dataService.allUsers.first(where: { $0.id == partnerId }),
                  meta.lastMessageText != nil else { return nil }
            return (friend: friend, lastMessage: meta, unreadCount: meta.unreadCount)
        }
        .sorted { ($0.lastMessage.lastMessageTimestamp ?? .distantPast) > ($1.lastMessage.lastMessageTimestamp ?? .distantPast) }
    }
}

struct ConversationRow: View {
    @EnvironmentObject var dataService: DataService
    let friend: User
    let meta: ConversationMeta
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarView(userId: friend.id, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(friend.displayName)
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundColor(AppTheme.darkText)
                    Spacer()
                    if let timestamp = meta.lastMessageTimestamp {
                        Text(timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(AppTheme.mutedText)
                    }
                }

                HStack {
                    Text(meta.lastMessageText ?? "")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                        .lineLimit(1)
                    Spacer()
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(AppTheme.accentGreen))
                    }
                }
            }
        }
        .cardStyle()
    }
}
