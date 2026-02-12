import Foundation
import CoreLocation

struct Course: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let city: String
    let state: String
    let phone: String
    let holes: Int
    let par: Int
    let latitude: Double
    let longitude: Double
    let distanceFromChicago: Double // miles

    var formattedDistance: String {
        String(format: "%.1f mi", distanceFromChicago)
    }

    func distance(from location: CLLocation) -> Double {
        let courseLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: courseLocation) / 1609.344
    }

    func formattedDistance(from location: CLLocation) -> String {
        String(format: "%.1f mi", distance(from: location))
    }

    var fullAddress: String {
        "\(address), \(city), \(state)"
    }

    // Chicago downtown coordinates
    private static let chicagoLat = 41.8781
    private static let chicagoLon = -87.6298

    static func distanceFromChicago(latitude: Double, longitude: Double) -> Double {
        let chicago = CLLocation(latitude: chicagoLat, longitude: chicagoLon)
        let course = CLLocation(latitude: latitude, longitude: longitude)
        return chicago.distance(from: course) / 1609.344 // meters to miles
    }
}
