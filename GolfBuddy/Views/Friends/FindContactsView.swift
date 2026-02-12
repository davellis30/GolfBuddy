import SwiftUI
import Contacts

struct FindContactsView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var matchedUsers: [User] = []
    @State private var unmatchedContacts: [ContactsService.UnmatchedContact] = []
    @State private var viewState: ViewState = .initial
    @State private var showShareSheet = false
    @State private var shareText = ""

    private let contactsService = ContactsService.shared

    enum ViewState {
        case initial
        case loading
        case denied
        case results
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                switch viewState {
                case .initial:
                    initialView
                case .loading:
                    ProgressView("Syncing contacts...")
                        .font(AppTheme.bodyFont)
                case .denied:
                    deniedView
                case .results:
                    resultsView
                }
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(text: shareText)
            }
        }
    }

    // MARK: - Initial State

    private var initialView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.accentGreen)

            Text("Find Friends from Contacts")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.darkText)

            Text("See which of your contacts are already on GolfBuddy and add them as friends.")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Sync Contacts") {
                syncContacts()
            }
            .buttonStyle(GreenButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Denied State

    private var deniedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.mutedText)

            Text("Contacts Access Required")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.darkText)

            Text("Enable Contacts access in Settings to find friends from your phone contacts.")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(OutlineButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if !matchedUsers.isEmpty {
                    sectionHeader("On GolfBuddy", count: matchedUsers.count)

                    ForEach(matchedUsers) { user in
                        matchedUserRow(user)
                    }
                }

                if !unmatchedContacts.isEmpty {
                    sectionHeader("Invite to GolfBuddy", count: unmatchedContacts.count)
                        .padding(.top, matchedUsers.isEmpty ? 0 : 10)

                    ForEach(unmatchedContacts) { contact in
                        unmatchedContactRow(contact)
                    }
                }

                if matchedUsers.isEmpty && unmatchedContacts.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.mutedText)
                        Text("No contacts found")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.mutedText)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.mutedText)
                .textCase(.uppercase)
            Spacer()
            Text("\(count)")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.mutedText)
        }
        .padding(.horizontal, 4)
    }

    private func matchedUserRow(_ user: User) -> some View {
        HStack(spacing: 14) {
            AvatarView(userId: user.id, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundColor(AppTheme.darkText)
                Text("@\(user.username)")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            if user.id == dataService.currentUser?.id {
                Text("You")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            } else if dataService.isFriend(user.id) {
                Label("Friends", systemImage: "checkmark")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.accentGreen)
            } else if dataService.hasPendingRequest(with: user.id) {
                Text("Requested")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            } else {
                Button(action: {
                    dataService.sendFriendRequest(to: user.id)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
        }
        .cardStyle()
    }

    private func unmatchedContactRow(_ contact: ContactsService.UnmatchedContact) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.darkCream)
                    .frame(width: 44, height: 44)
                Text(contactInitials(contact.name))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.mutedText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundColor(AppTheme.darkText)
                if let email = contact.email {
                    Text(email)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                }
            }

            Spacer()

            Button(action: {
                shareText = "Hey! Join me on GolfBuddy to coordinate weekend golf rounds. Download it here: https://golfbuddy.app"
                showShareSheet = true
            }) {
                Text("Invite")
                    .font(AppTheme.captionFont.weight(.semibold))
                    .foregroundColor(AppTheme.accentGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.accentGreen, lineWidth: 1.5)
                    )
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private func contactInitials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func syncContacts() {
        viewState = .loading

        Task {
            let status = contactsService.accessStatus
            if status == .denied {
                await MainActor.run { viewState = .denied }
                return
            }

            let granted = await contactsService.requestAccess()
            if !granted {
                await MainActor.run { viewState = .denied }
                return
            }

            let result = contactsService.matchContacts(against: dataService.allUsers)
            await MainActor.run {
                matchedUsers = result.matched
                unmatchedContacts = result.unmatched
                viewState = .results
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
