import SwiftUI

struct MonthCalendarGrid: View {
    @Binding var displayMonth: Date
    let entries: [String: WeekendAvailability]
    var onDateTap: ((Date) -> Void)?
    var isEditable: Bool = true

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayMonth)
    }

    private var daysInMonth: [DateCell] {
        let range = calendar.range(of: .day, in: .month, for: displayMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1=Sun

        var cells: [DateCell] = []
        var position = 0

        // Leading empty cells
        for _ in 0..<(firstWeekday - 1) {
            cells.append(DateCell(id: position, date: nil, dayNumber: 0))
            position += 1
        }

        // Day cells
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                cells.append(DateCell(id: position, date: date, dayNumber: day))
                position += 1
            }
        }

        return cells
    }

    private var isCurrentMonth: Bool {
        let now = Date()
        return calendar.component(.year, from: displayMonth) == calendar.component(.year, from: now)
            && calendar.component(.month, from: displayMonth) == calendar.component(.month, from: now)
    }

    private func isPast(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isCurrentMonth ? AppTheme.mutedText.opacity(0.3) : AppTheme.accentGreen)
                        .frame(width: 36, height: 36)
                }
                .disabled(isCurrentMonth)

                Spacer()

                Text(monthTitle)
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.darkText)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.accentGreen)
                        .frame(width: 36, height: 36)
                }
            }

            // Day-of-week headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.mutedText)
                        .frame(height: 20)
                }
            }

            // Date cells
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth) { cell in
                    if let date = cell.date {
                        let key = CalendarEntry.dateKey(from: date)
                        let availability = entries[key]
                        let past = isPast(date)
                        let today = isToday(date)

                        Button {
                            if isEditable && !past {
                                onDateTap?(date)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(cell.dayNumber)")
                                    .font(.system(size: 15, weight: today ? .bold : .regular, design: .rounded))
                                    .foregroundColor(past ? AppTheme.mutedText.opacity(0.4) : (today ? AppTheme.accentGreen : AppTheme.darkText))

                                if let availability = availability {
                                    Circle()
                                        .fill(availability.color)
                                        .frame(width: 7, height: 7)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 7, height: 7)
                                }
                            }
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(today ? AppTheme.accentGreen.opacity(0.08) : Color.clear)
                            )
                        }
                        .disabled(!isEditable || past)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: entries.count)
    }
}

private struct DateCell: Identifiable {
    let id: Int // grid position (0-based)
    let date: Date?
    let dayNumber: Int
}

// MARK: - Legend

struct CalendarLegend: View {
    var body: some View {
        HStack(spacing: 20) {
            legendItem(color: WeekendAvailability.lookingToPlay.color, label: "Looking to Play")
            legendItem(color: WeekendAvailability.alreadyPlaying.color, label: "Playing")
            legendItem(color: WeekendAvailability.seekingAdditional.color, label: "Need 1 More")
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(AppTheme.mutedText)
        }
    }
}

// MARK: - My Calendar View

struct MyCalendarView: View {
    @EnvironmentObject var dataService: DataService
    @State private var displayMonth = Date()
    @State private var selectedDate: Date?
    @State private var showStatusPicker = false

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    MonthCalendarGrid(
                        displayMonth: $displayMonth,
                        entries: dataService.myCalendarEntries,
                        onDateTap: { date in
                            selectedDate = date
                            showStatusPicker = true
                        },
                        isEditable: true
                    )
                    .cardStyle()
                    .padding(.horizontal, 20)

                    CalendarLegend()
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("My Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dataService.loadMyCalendar()
        }
        .confirmationDialog(
            statusDialogTitle,
            isPresented: $showStatusPicker,
            titleVisibility: .visible
        ) {
            Button("Looking to Play") {
                if let date = selectedDate {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.setCalendarEntry(date: date, availability: .lookingToPlay)
                    }
                }
            }
            Button("Already Playing") {
                if let date = selectedDate {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.setCalendarEntry(date: date, availability: .alreadyPlaying)
                    }
                }
            }
            Button("Seeking a Fourth") {
                if let date = selectedDate {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.setCalendarEntry(date: date, availability: .seekingAdditional)
                    }
                }
            }
            if let date = selectedDate, dataService.myCalendarEntries[CalendarEntry.dateKey(from: date)] != nil {
                Button("Clear", role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.clearCalendarEntry(date: date)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var statusDialogTitle: String {
        guard let date = selectedDate else { return "Set Status" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
