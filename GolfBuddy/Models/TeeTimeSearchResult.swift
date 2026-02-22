import Foundation

struct TeeTimeSearchResult: Identifiable {
    let id: String
    let course: Course
    let teeTimes: [TeeTime]
    let searchedAt: Date

    var isEmpty: Bool { teeTimes.isEmpty }
}
