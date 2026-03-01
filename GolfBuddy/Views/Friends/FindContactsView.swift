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
    @State private var isLimitedAccess = false

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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                guard viewState == .results else { return }
                syncContacts()
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
                if isLimitedAccess {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 20))
                            Text("You've shared limited contacts. Tap to add more.")
                                .font(AppTheme.captionFont)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.accentGreen)
                        )
                    }
                }

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

            if status == .notDetermined {
                let granted = await contactsService.requestAccess()
                if !granted {
                    await MainActor.run { viewState = .denied }
                    return
                }
            }

            let currentStatus = contactsService.accessStatus
            let contacts = contactsService.fetchContacts()

            // Collect emails and normalized phone numbers from contacts
            let emails = Array(Set(
                contacts.flatMap { $0.emailAddresses.map { ($0.value as String).lowercased() } }
            ))
            let phones = Array(Set(
                contacts.flatMap { $0.phoneNumbers.map { User.normalizePhoneNumber($0.value.stringValue) } }
            )).filter { !$0.isEmpty }

            // Query Firestore for matching users by email and phone
            var matchedByIdMap: [String: User] = [:]

            if !emails.isEmpty {
                let emailUsers = (try? await FirestoreService.shared.fetchUsersByEmails(emails)) ?? []
                for user in emailUsers { matchedByIdMap[user.id] = user }
            }
            if !phones.isEmpty {
                let phoneUsers = (try? await FirestoreService.shared.fetchUsersByPhoneNumbers(phones)) ?? []
                for user in phoneUsers { matchedByIdMap[user.id] = user }
            }

            // Filter out current user and existing friends
            let currentId = dataService.currentUser?.id ?? ""
            let friendIds = dataService.friendships[currentId] ?? []
            let matched = matchedByIdMap.values.filter { $0.id != currentId && !friendIds.contains($0.id) }

            // Build unmatched contacts list
            let matchedEmails = Set(matched.map { $0.email.lowercased() })
            let matchedPhones = Set(matched.compactMap { user -> String? in
                guard let phone = user.phoneNumber, !phone.isEmpty else { return nil }
                return User.normalizePhoneNumber(phone)
            })

            var unmatched: [ContactsService.UnmatchedContact] = []
            for contact in contacts {
                let fullName = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                guard !fullName.isEmpty else { continue }

                let contactEmails = contact.emailAddresses.map { ($0.value as String).lowercased() }
                let contactPhones = contact.phoneNumbers.map { User.normalizePhoneNumber($0.value.stringValue) }

                let emailMatch = contactEmails.contains { matchedEmails.contains($0) }
                let phoneMatch = contactPhones.contains { matchedPhones.contains($0) }

                if !emailMatch && !phoneMatch {
                    unmatched.append(ContactsService.UnmatchedContact(
                        name: fullName,
                        email: contact.emailAddresses.first?.value as String?,
                        phone: contact.phoneNumbers.first?.value.stringValue
                    ))
                }
            }

            await MainActor.run {
                isLimitedAccess = currentStatus == .limited
                matchedUsers = matched.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                unmatchedContacts = unmatched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
