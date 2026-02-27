import Foundation
import SwiftUI

enum CardColorTheme: String, CaseIterable, Codable {
    case classicGreen = "classicGreen"
    case navyBlue = "navyBlue"
    case sunsetOrange = "sunsetOrange"
    case royalPurple = "royalPurple"
    case slateGray = "slateGray"

    var color: Color {
        switch self {
        case .classicGreen: return AppTheme.accentGreen
        case .navyBlue: return Color(red: 0.15, green: 0.30, blue: 0.60)
        case .sunsetOrange: return Color(red: 0.90, green: 0.45, blue: 0.20)
        case .royalPurple: return Color(red: 0.45, green: 0.25, blue: 0.65)
        case .slateGray: return Color(red: 0.40, green: 0.45, blue: 0.50)
        }
    }

    var label: String {
        switch self {
        case .classicGreen: return "Green"
        case .navyBlue: return "Navy"
        case .sunsetOrange: return "Sunset"
        case .royalPurple: return "Purple"
        case .slateGray: return "Slate"
        }
    }
}

struct User: Identifiable, Codable, Hashable {
    let id: String
    var username: String
    var displayName: String
    var email: String
    var handicap: Double?
    var homeCourse: String?
    var profilePhotoUrl: String?
    var cardColorTheme: String?
    var statusTagline: String?

    var avatarInitials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    var themeColor: CardColorTheme {
        if let raw = cardColorTheme, let theme = CardColorTheme(rawValue: raw) {
            return theme
        }
        return .classicGreen
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
        self.profilePhotoUrl = data["profilePhotoUrl"] as? String
        self.cardColorTheme = data["cardColorTheme"] as? String
        self.statusTagline = data["statusTagline"] as? String
    }
}
