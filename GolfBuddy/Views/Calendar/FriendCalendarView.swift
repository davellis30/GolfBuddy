import SwiftUI

struct FriendCalendarView: View {
    @EnvironmentObject var dataService: DataService
    let friend: User
    @State private var displayMonth = Date()
    @State private var entries: [String: WeekendAvailability] = [:]
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppTheme.accentGreen)
                    Text("Loading calendar...")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        MonthCalendarGrid(
                            displayMonth: $displayMonth,
                            entries: entries,
                            isEditable: false
                        )
                        .cardStyle()
                        .padding(.horizontal, 20)

                        if entries.isEmpty {
                            Text("No availability set yet")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.mutedText)
                                .padding(.top, 8)
                        } else {
                            CalendarLegend()
                                .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .navigationTitle("\(friend.displayName)'s Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            entries = await dataService.fetchFriendCalendar(userId: friend.id)
            isLoading = false
        }
    }
}
