import Foundation

struct TeeTime: Identifiable, Hashable {
    let id: String
    let courseId: String
    let courseName: String
    let date: Date
    let availableSlots: Int
    let pricePerPlayer: Double
    let holes: Int
    let isHotDeal: Bool

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var formattedPrice: String {
        String(format: "$%.0f", pricePerPlayer)
    }
}
