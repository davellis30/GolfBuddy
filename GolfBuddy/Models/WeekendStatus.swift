import Foundation
import SwiftUI

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
    var weekendDate: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        availability: WeekendAvailability,
        isVisible: Bool = true,
        shareDetails: Bool = false,
        courseName: String? = nil,
        playingWith: [UUID] = [],
        weekendDate: Date = WeekendStatus.nextWeekend()
    ) {
        self.id = id
        self.userId = userId
        self.availability = availability
        self.isVisible = isVisible
        self.shareDetails = shareDetails
        self.courseName = courseName
        self.playingWith = playingWith
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
