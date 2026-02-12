import Foundation
import SwiftUI

enum WeekendDay: String, Codable, CaseIterable {
    case saturday, sunday

    var shortLabel: String {
        switch self {
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

enum DayTime: String, Codable, CaseIterable {
    case am, pm

    var shortLabel: String {
        switch self {
        case .am: return "AM"
        case .pm: return "PM"
        }
    }
}

struct DayTimeSlot: Codable, Hashable {
    let day: WeekendDay
    let time: DayTime

    var label: String {
        "\(day.shortLabel) \(time.shortLabel)"
    }

    static let allSlots: [DayTimeSlot] = [
        DayTimeSlot(day: .saturday, time: .am),
        DayTimeSlot(day: .saturday, time: .pm),
        DayTimeSlot(day: .sunday, time: .am),
        DayTimeSlot(day: .sunday, time: .pm)
    ]
}

enum WeekendAvailability: String, Codable, CaseIterable {
    case lookingToPlay = "Looking to Play"
    case alreadyPlaying = "Already Playing"
    case seekingAdditional = "Seeking an Additional Player"

    var icon: String {
        switch self {
        case .lookingToPlay: return "figure.golf"
        case .alreadyPlaying: return "checkmark.circle.fill"
        case .seekingAdditional: return "person.badge.plus"
        }
    }

    var color: Color {
        switch self {
        case .lookingToPlay: return AppTheme.statusLooking
        case .alreadyPlaying: return AppTheme.statusPlaying
        case .seekingAdditional: return AppTheme.statusSeeking
        }
    }

    var shortLabel: String {
        switch self {
        case .lookingToPlay: return "Looking"
        case .alreadyPlaying: return "Playing"
        case .seekingAdditional: return "Need 1 More"
        }
    }
}

struct WeekendStatus: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var availability: WeekendAvailability
    var isVisible: Bool
    var shareDetails: Bool
    var courseName: String?
    var playingWith: [UUID]
    var timeSlots: [DayTimeSlot]
    var preferredTimeSlot: DayTimeSlot?
    var weekendDate: Date

    var formattedTimeSlots: String {
        timeSlots.map { $0.label }.joined(separator: " · ")
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        availability: WeekendAvailability,
        isVisible: Bool = true,
        shareDetails: Bool = false,
        courseName: String? = nil,
        playingWith: [UUID] = [],
        timeSlots: [DayTimeSlot] = [],
        preferredTimeSlot: DayTimeSlot? = nil,
        weekendDate: Date = WeekendStatus.nextWeekend()
    ) {
        self.id = id
        self.userId = userId
        self.availability = availability
        self.isVisible = isVisible
        self.shareDetails = shareDetails
        self.courseName = courseName
        self.playingWith = playingWith
        self.timeSlots = timeSlots
        self.preferredTimeSlot = preferredTimeSlot
        self.weekendDate = weekendDate
    }

    static func nextWeekend() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // Saturday = 7
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let offset = daysUntilSaturday == 0 ? 0 : daysUntilSaturday
        return calendar.date(byAdding: .day, value: offset, to: today) ?? today
    }

    static func weekendLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let saturday = nextWeekend()
        let sunday = Calendar.current.date(byAdding: .day, value: 1, to: saturday)!
        return "\(formatter.string(from: saturday)) - \(formatter.string(from: sunday))"
    }
}
