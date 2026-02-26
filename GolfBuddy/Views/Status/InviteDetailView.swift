import SwiftUI

struct InviteDetailView: View {
    @EnvironmentObject var dataService: DataService
    let invite: OpenInvite

    private var isCreator: Bool {
        dataService.currentUser?.id == invite.creatorId
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Course + time slot header
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.accentGreen)
                            Text(invite.courseName)
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.darkText)
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Text(invite.timeSlot.label)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.accentGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.accentGreen.opacity(0.12))
                                )

                            Text(WeekendStatus.weekendLabel())
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)

                            Spacer()
                        }
                    }
                    .cardStyle()

                    // Creator info
                    HStack(spacing: 12) {
                        AvatarView(userId: invite.creatorId, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isCreator ? "Your Invite" : dataService.userName(for: invite.creatorId))
                                .font(AppTheme.bodyFont.weight(.semibold))
                                .foregroundColor(AppTheme.darkText)
                            Text("Organizer")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)
                        }
                        Spacer()
                    }
                    .cardStyle()

                    // Spots visual
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PLAYERS (\(invite.approvedPlayerIds.count)/\(invite.groupSize))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.mutedText)
                            .tracking(1)

                        HStack(spacing: 12) {
                            ForEach(0..<invite.groupSize, id: \.self) { index in
                                if index < invite.approvedPlayerIds.count {
                                    AvatarView(userId: invite.approvedPlayerIds[index], size: 44)
                                } else {
                                    Circle()
                                        .strokeBorder(AppTheme.mutedText.opacity(0.3), lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 16))
                                                .foregroundColor(AppTheme.mutedText.opacity(0.5))
                                        )
                                }
                            }
                            Spacer()
                        }

                        ForEach(invite.approvedPlayerIds, id: \.self) { playerId in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accentGreen)
                                    .font(.system(size: 14))
                                Text(playerId == invite.creatorId ? "\(dataService.userName(for: playerId)) (Host)" : dataService.userName(for: playerId))
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.darkText)
                                Spacer()
                            }
                        }
                    }
                    .cardStyle()

                    // Creator view: pending requests
                    if isCreator {
                        let pendingRequests = invite.joinRequests.filter { $0.status == .pending }
                        if !pendingRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("JOIN REQUESTS")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.mutedText)
                                    .tracking(1)

                                ForEach(pendingRequests) { request in
                                    HStack(spacing: 14) {
                                        AvatarView(userId: request.userId, size: 44)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dataService.userName(for: request.userId))
                                                .font(AppTheme.bodyFont.weight(.semibold))
                                                .foregroundColor(AppTheme.darkText)
                                            Text("Wants to join")
                                                .font(AppTheme.captionFont)
                                                .foregroundColor(AppTheme.mutedText)
                                        }

                                        Spacer()

                                        HStack(spacing: 8) {
                                            Button {
                                                dataService.approveJoinRequest(invite: invite, request: request)
                                            } label: {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(AppTheme.accentGreen)
                                            }

                                            Button {
                                                dataService.declineJoinRequest(invite: invite, request: request)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(AppTheme.mutedText)
                                            }
                                        }
                                    }
                                    .cardStyle()
                                }
                            }
                        }

                        // Cancel invite button
                        if invite.status != .cancelled {
                            Button("Cancel Invite") {
                                dataService.cancelOpenInvite(invite)
                            }
                            .buttonStyle(OutlineButtonStyle())
                            .foregroundColor(AppTheme.statusSeeking)
                        }
                    } else {
                        // Friend view
                        friendActionSection
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Invite Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var friendActionSection: some View {
        let currentId = dataService.currentUser?.id ?? ""
        let myRequest = invite.joinRequests.first { $0.userId == currentId }
        let isApproved = invite.approvedPlayerIds.contains(currentId)

        if isApproved {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(AppTheme.accentGreen)
                Text("You're In!")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.accentGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.accentGreen.opacity(0.12))
            )
        } else if let myRequest = myRequest {
            if myRequest.status == .pending {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppTheme.gold)
                    Text("Request Pending")
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundColor(AppTheme.gold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.gold.opacity(0.12))
                )
            } else if myRequest.status == .declined {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(AppTheme.mutedText)
                    Text("Request Declined")
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundColor(AppTheme.mutedText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.mutedText.opacity(0.12))
                )
            }
        } else if invite.status == .open && invite.spotsRemaining > 0 {
            Button("Request to Join") {
                dataService.requestToJoinInvite(invite)
            }
            .buttonStyle(GreenButtonStyle())
        }
    }
}
