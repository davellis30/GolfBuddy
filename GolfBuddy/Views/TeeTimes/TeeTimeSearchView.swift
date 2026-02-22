import SwiftUI
import CoreLocation

struct TeeTimeSearchView: View {
    @EnvironmentObject var dataService: DataService
    @ObservedObject private var locationService = LocationService.shared
    @StateObject private var searchService = TeeTimeSearchService()

    var preselectedCourse: Course?

    @State private var selectedCourseIds: Set<String> = []
    @State private var selectedDate = Self.nextSaturday()
    @State private var selectedTimeWindows: Set<TimeWindow> = [.morning]
    @State private var numberOfPlayers = 2
    @State private var showResults = false
    @State private var searchRequest: TeeTimeSearchRequest?

    private var sortedCourses: [Course] {
        let courses = dataService.nearbyCourses
        return courses.sorted { a, b in
            let aFav = searchService.isFavorite(a.id)
            let bFav = searchService.isFavorite(b.id)
            if aFav != bFav { return aFav }
            return false
        }
    }

    private var canSearch: Bool {
        !selectedCourseIds.isEmpty && !selectedTimeWindows.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Course selection
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("COURSES")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.mutedText)
                                .tracking(1)
                            Spacer()
                            Text("\(selectedCourseIds.count) selected")
                                .font(AppTheme.captionFont)
                                .foregroundColor(selectedCourseIds.count >= 1 ? AppTheme.accentGreen : AppTheme.mutedText)
                        }

                        ForEach(sortedCourses) { course in
                            CourseSelectionRow(
                                course: course,
                                isSelected: selectedCourseIds.contains(course.id),
                                isFavorite: searchService.isFavorite(course.id),
                                userLocation: locationService.userLocation,
                                onToggle: {
                                    if selectedCourseIds.contains(course.id) {
                                        selectedCourseIds.remove(course.id)
                                    } else if selectedCourseIds.count < 5 {
                                        selectedCourseIds.insert(course.id)
                                    }
                                },
                                onFavoriteToggle: {
                                    searchService.toggleFavorite(course.id)
                                }
                            )
                        }

                        if selectedCourseIds.count >= 5 {
                            Text("Maximum 5 courses selected")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)
                        }
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DATE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.mutedText)
                            .tracking(1)

                        DatePicker(
                            "Select date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.accentGreen)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        )
                    }

                    // Time windows
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TIME")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.mutedText)
                            .tracking(1)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(TimeWindow.allCases, id: \.self) { window in
                                Button {
                                    if selectedTimeWindows.contains(window) {
                                        selectedTimeWindows.remove(window)
                                    } else {
                                        selectedTimeWindows.insert(window)
                                    }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(window.label)
                                            .font(AppTheme.bodyFont.weight(.medium))
                                        Text(window.timeRange)
                                            .font(.system(size: 11, design: .rounded))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedTimeWindows.contains(window) ? AppTheme.accentGreen : Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedTimeWindows.contains(window) ? Color.clear : AppTheme.mutedText.opacity(0.3), lineWidth: 1)
                                    )
                                    .foregroundColor(selectedTimeWindows.contains(window) ? .white : AppTheme.darkText)
                                }
                            }
                        }
                    }

                    // Players
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PLAYERS")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.mutedText)
                            .tracking(1)

                        HStack(spacing: 10) {
                            ForEach(1...4, id: \.self) { count in
                                Button {
                                    numberOfPlayers = count
                                } label: {
                                    Text("\(count)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(numberOfPlayers == count ? AppTheme.accentGreen : Color.white)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(numberOfPlayers == count ? Color.clear : AppTheme.mutedText.opacity(0.3), lineWidth: 1)
                                        )
                                        .foregroundColor(numberOfPlayers == count ? .white : AppTheme.darkText)
                                }
                            }
                        }
                    }

                    // Search button
                    Button {
                        performSearch()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Search Tee Times")
                        }
                    }
                    .buttonStyle(GreenButtonStyle())
                    .disabled(!canSearch)
                    .opacity(canSearch ? 1 : 0.5)

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Find Tee Times")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResults) {
            TeeTimeResultsView(searchService: searchService)
        }
        .onAppear {
            if let course = preselectedCourse {
                selectedCourseIds.insert(course.id)
            }
        }
    }

    private func performSearch() {
        let courses = dataService.nearbyCourses.filter { selectedCourseIds.contains($0.id) }
        let (earliest, latest) = timeRange(for: selectedTimeWindows, on: selectedDate)

        let request = TeeTimeSearchRequest(
            courses: courses,
            date: selectedDate,
            earliestTime: earliest,
            latestTime: latest,
            numberOfPlayers: numberOfPlayers
        )

        showResults = true
        Task {
            await searchService.search(request: request)
        }
    }

    private func timeRange(for windows: Set<TimeWindow>, on date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let sorted = windows.sorted { $0.startHour < $1.startHour }
        let earliest = sorted.first?.startHour ?? 6
        let latest = sorted.last?.endHour ?? 17

        let start = calendar.date(bySettingHour: earliest, minute: 0, second: 0, of: date) ?? date
        let end = calendar.date(bySettingHour: latest, minute: 0, second: 0, of: date) ?? date
        return (start, end)
    }

    static func nextSaturday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSaturday = (7 - weekday) % 7
        let offset = daysUntilSaturday == 0 ? 7 : daysUntilSaturday
        return calendar.date(byAdding: .day, value: offset, to: today) ?? today
    }
}

// MARK: - Time Window

enum TimeWindow: String, CaseIterable {
    case earlyBird = "Early Bird"
    case morning = "Morning"
    case midday = "Midday"
    case afternoon = "Afternoon"

    var label: String { rawValue }

    var timeRange: String {
        switch self {
        case .earlyBird: return "Before 8 AM"
        case .morning: return "8 - 11 AM"
        case .midday: return "11 AM - 2 PM"
        case .afternoon: return "2 - 5 PM"
        }
    }

    var startHour: Int {
        switch self {
        case .earlyBird: return 6
        case .morning: return 8
        case .midday: return 11
        case .afternoon: return 14
        }
    }

    var endHour: Int {
        switch self {
        case .earlyBird: return 8
        case .morning: return 11
        case .midday: return 14
        case .afternoon: return 17
        }
    }
}
