import SwiftUI

struct FriendRequestsView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        let pending = dataService.pendingRequestsForCurrentUser()
                        let sent = dataService.sentRequestsForCurrentUser()

                        if pending.isEmpty && sent.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 44))
                                    .foregroundColor(AppTheme.mutedText)
                                Text("No pending requests")
                                    .font(AppTheme.headlineFont)
                                    .foregroundColor(AppTheme.darkText)
                            }
                            .padding(.top, 60)
                        }

                        if !pending.isEmpty {
                            SectionHeader(title: "Received")

                            ForEach(pending) { request in
                                if let sender = dataService.allUsers.first(where: { $0.id == request.fromUserId }) {
                                    IncomingRequestRow(sender: sender, request: request)
                                }
                            }
                        }

                        if !sent.isEmpty {
                            SectionHeader(title: "Sent")

                            ForEach(sent) { request in
                                if let recipient = dataService.allUsers.first(where: { $0.id == request.toUserId }) {
                                    SentRequestRow(recipient: recipient)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
        }
    }
}

struct IncomingRequestRow: View {
    @EnvironmentObject var dataService: DataService
    let sender: User
    let request: FriendRequest

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGreen)
                    .frame(width: 44, height: 44)
                Text(sender.avatarInitials)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sender.displayName)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundColor(AppTheme.darkText)
                Text("@\(sender.username)")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: { dataService.acceptFriendRequest(request) }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.accentGreen)
                }

                Button(action: { dataService.declineFriendRequest(request) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.mutedText)
                }
            }
        }
        .cardStyle()
    }
}

struct SentRequestRow: View {
    let recipient: User

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.darkCream)
                    .frame(width: 44, height: 44)
                Text(recipient.avatarInitials)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.accentGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(recipient.displayName)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundColor(AppTheme.darkText)
                Text("@\(recipient.username)")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            Text("Pending")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.statusSeeking)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .stroke(AppTheme.statusSeeking, lineWidth: 1)
                )
        }
        .cardStyle()
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.mutedText)
                .tracking(1)
            Spacer()
        }
        .padding(.top, 8)
    }
}
