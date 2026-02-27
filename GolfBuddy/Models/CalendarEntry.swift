import Foundation
import FirebaseFirestore

struct CalendarEntry {
    let userId: String
    var entries: [String: WeekendAvailability]  // "YYYY-MM-DD" -> availability
    var updatedAt: Date

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone.current
        return fmt
    }()

    static func dateKey(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        dateFormatter.date(from: key)
    }

    init(userId: String, entries: [String: WeekendAvailability] = [:], updatedAt: Date = Date()) {
        self.userId = userId
        self.entries = entries
        self.updatedAt = updatedAt
    }

    func toFirestoreData() -> [String: Any] {
        var entriesMap: [String: String] = [:]
        for (key, value) in entries {
            entriesMap[key] = value.rawValue
        }
        return [
            "userId": userId,
            "entries": entriesMap,
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    init?(fromFirestore data: [String: Any]) {
        guard let userId = data["userId"] as? String else { return nil }
        self.userId = userId
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

        var parsed: [String: WeekendAvailability] = [:]
        if let entriesMap = data["entries"] as? [String: String] {
            for (key, rawValue) in entriesMap {
                if let availability = WeekendAvailability(rawValue: rawValue) {
                    parsed[key] = availability
                }
            }
        }
        self.entries = parsed
    }
}
