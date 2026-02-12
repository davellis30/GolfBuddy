import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    var username: String
    var displayName: String
    var email: String
    var handicap: Double?
    var homeCourse: String?
    var avatarInitials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension User {
    init?(fromFirestore data: [String: Any]) {
        guard let id = data["id"] as? String else { return nil }
        self.id = id
        self.username = data["username"] as? String ?? ""
        self.displayName = data["displayName"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.handicap = data["handicap"] as? Double
        self.homeCourse = data["homeCourse"] as? String
    }
}
