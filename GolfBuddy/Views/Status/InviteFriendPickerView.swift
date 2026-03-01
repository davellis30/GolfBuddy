import SwiftUI

struct InviteFriendPickerView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    let invite: OpenInvite

    private var availableFriends: [(User, WeekendStatus)] {
        dataService.friendsLookingToPlay(excludingInvite: invite)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                if availableFriends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.mutedText)
                        Text("None of your friends are looking to play this weekend")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(availableFriends, id: \.0.id) { friend, status in
                                Button {
                                    dataService.sendDirectInvite(invite: invite, toUserId: friend.id)
                                    dismiss()
                                } label: {
                                    FriendPickerRow(friend: friend, status: status)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Invite a Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
        }
    }
}

private struct FriendPickerRow: View {
    @EnvironmentObject var dataService: DataService
    let friend: User
    let status: WeekendStatus

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(userId: friend.id, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundColor(AppTheme.darkText)

                if let tagline = friend.activeTagline {
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

            Image(systemName: "paperplane.fill")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accentGreen)
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
