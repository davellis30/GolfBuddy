import Foundation
import CoreLocation

struct Course: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let city: String
    let phone: String
    let holes: Int
    let par: Int
    let latitude: Double
    let longitude: Double
    let distanceFromChicago: Double // miles

    var formattedDistance: String {
        String(format: "%.1f mi", distanceFromChicago)
    }

    var fullAddress: String {
        "\(address), \(city), IL"
    }
}
