import SwiftUI

struct AddFriendView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showFindContacts = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Find from Contacts button
                    Button(action: { showFindContacts = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.rectangle.stack")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.accentGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Find from Contacts")
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(AppTheme.darkText)
                                Text("See which contacts are on GolfBuddy")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.mutedText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.mutedText)
                        }
                        .cardStyle()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.mutedText)
                        TextField("Search by name or username", text: $searchText)
                            .font(AppTheme.bodyFont)
                            .textInputAutocapitalization(.never)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.mutedText)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Results
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if searchText.count >= 2 {
                                let results = dataService.searchUsers(query: searchText)
                                if results.isEmpty {
                                    VStack(spacing: 10) {
                                        Image(systemName: "person.slash")
                                            .font(.system(size: 36))
                                            .foregroundColor(AppTheme.mutedText)
                                        Text("No users found")
                                            .font(AppTheme.bodyFont)
                                            .foregroundColor(AppTheme.mutedText)
                                    }
                                    .padding(.top, 40)
                                } else {
                                    ForEach(results) { user in
                                        SearchResultRow(user: user)
                                    }
                                }
                            } else if searchText.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 36))
                                        .foregroundColor(AppTheme.mutedText)
                                    Text("Search for players to add")
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
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
            .sheet(isPresented: $showFindContacts) {
                FindContactsView()
                    .environmentObject(dataService)
            }
        }
    }
}

struct SearchResultRow: View {
    @EnvironmentObject var dataService: DataService
    let user: User
    @State private var requestSent = false

    var body: some View {
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

            if dataService.isFriend(user.id) {
                Label("Friends", systemImage: "checkmark")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.accentGreen)
            } else if requestSent || dataService.hasPendingRequest(with: user.id) {
                Text("Requested")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            } else {
                Button(action: {
                    dataService.sendFriendRequest(to: user.id)
                    requestSent = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
        }
        .cardStyle()
    }
}
