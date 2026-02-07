import SwiftUI

struct SetStatusView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAvailability: WeekendAvailability = .lookingToPlay
    @State private var isVisible = true
    @State private var shareDetails = false
    @State private var selectedCourse: String = ""
    @State private var selectedPlayingWith: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Weekend label
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppTheme.accentGreen)
                            Text(WeekendStatus.weekendLabel())
                                .font(AppTheme.bodyFont.weight(.medium))
                                .foregroundColor(AppTheme.darkText)
                        }
                        .padding(.top, 8)

                        // Status selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("YOUR STATUS")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.mutedText)
                                .tracking(1)

                            ForEach(WeekendAvailability.allCases, id: \.self) { availability in
                                StatusOption(
                                    availability: availability,
                                    isSelected: selectedAvailability == availability,
                                    action: { selectedAvailability = availability }
                                )
                            }
                        }

                        // Visibility toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Text("VISIBILITY")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.mutedText)
                                .tracking(1)

                            HStack {
                                Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(AppTheme.accentGreen)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Visible to Friends")
                                        .font(AppTheme.bodyFont.weight(.medium))
                                        .foregroundColor(AppTheme.darkText)
                                    Text(isVisible ? "Friends can see your status" : "Your status is hidden")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.mutedText)
                                }

                                Spacer()

                                Toggle("", isOn: $isVisible)
                                    .tint(AppTheme.accentGreen)
                                    .labelsHidden()
                            }
                            .cardStyle()
                        }

                        // Share details toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SHARE DETAILS")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.mutedText)
                                .tracking(1)

                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppTheme.accentGreen)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Share Course & Players")
                                        .font(AppTheme.bodyFont.weight(.medium))
                                        .foregroundColor(AppTheme.darkText)
                                    Text("Let friends see where and with whom you're playing")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.mutedText)
                                }

                                Spacer()

                                Toggle("", isOn: $shareDetails)
                                    .tint(AppTheme.accentGreen)
                                    .labelsHidden()
                            }
                            .cardStyle()
                        }

                        // Course picker (shown if sharing details)
                        if shareDetails {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("COURSE")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.mutedText)
                                    .tracking(1)

                                Menu {
                                    Button("None selected") { selectedCourse = "" }
                                    ForEach(dataService.courses) { course in
                                        Button("\(course.name) (\(course.formattedDistance))") {
                                            selectedCourse = course.name
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(AppTheme.accentGreen)
                                        Text(selectedCourse.isEmpty ? "Select a course" : selectedCourse)
                                            .font(AppTheme.bodyFont)
                                            .foregroundColor(selectedCourse.isEmpty ? AppTheme.mutedText : AppTheme.darkText)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(AppTheme.mutedText)
                                            .font(.caption)
                                    }
                                    .cardStyle()
                                }
                            }

                            // Playing with
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PLAYING WITH")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.mutedText)
                                    .tracking(1)

                                let myFriends = currentUserFriends
                                if myFriends.isEmpty {
                                    Text("Add friends to tag them here")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.mutedText)
                                } else {
                                    LazyVStack(spacing: 6) {
                                        ForEach(myFriends) { friend in
                                            FriendToggleRow(
                                                friend: friend,
                                                isSelected: selectedPlayingWith.contains(friend.id),
                                                toggle: {
                                                    if selectedPlayingWith.contains(friend.id) {
                                                        selectedPlayingWith.remove(friend.id)
                                                    } else {
                                                        selectedPlayingWith.insert(friend.id)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        // Save + Clear
                        VStack(spacing: 12) {
                            Button("Save Status") {
                                dataService.setWeekendStatus(
                                    availability: selectedAvailability,
                                    isVisible: isVisible,
                                    shareDetails: shareDetails,
                                    courseName: selectedCourse.isEmpty ? nil : selectedCourse,
                                    playingWith: Array(selectedPlayingWith)
                                )
                                dismiss()
                            }
                            .buttonStyle(GreenButtonStyle())

                            if dataService.weekendStatuses[dataService.currentUser?.id ?? UUID()] != nil {
                                Button("Clear Status") {
                                    dataService.clearWeekendStatus()
                                    dismiss()
                                }
                                .buttonStyle(OutlineButtonStyle())
                            }
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Set Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private var currentUserFriends: [User] {
        guard let userId = dataService.currentUser?.id else { return [] }
        return dataService.friends(of: userId)
    }

    private func loadExisting() {
        guard let userId = dataService.currentUser?.id,
              let status = dataService.weekendStatuses[userId] else { return }
        selectedAvailability = status.availability
        isVisible = status.isVisible
        shareDetails = status.shareDetails
        selectedCourse = status.courseName ?? ""
        selectedPlayingWith = Set(status.playingWith)
    }
}

struct StatusOption: View {
    let availability: WeekendAvailability
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: availability.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : availability.color)
                    .frame(width: 28)

                Text(availability.rawValue)
                    .font(AppTheme.bodyFont.weight(.medium))
                    .foregroundColor(isSelected ? .white : AppTheme.darkText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? availability.color : Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct FriendToggleRow: View {
    let friend: User
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.accentGreen : AppTheme.darkCream)
                        .frame(width: 36, height: 36)
                    Text(friend.avatarInitials)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : AppTheme.accentGreen)
                }

                Text(friend.displayName)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.darkText)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.accentGreen : AppTheme.mutedText)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            )
        }
    }
}
