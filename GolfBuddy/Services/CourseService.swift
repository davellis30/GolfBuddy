import Foundation
import CoreLocation

struct CourseService {

    // MARK: - JSON Bundle Loading

    /// All courses loaded from the bundled JSON file, merged with hardcoded Chicago courses
    static let allCourses: [Course] = {
        var courses: [Course] = []

        if let url = Bundle.main.url(forResource: "courses", withExtension: "json"),
           let data = try? Data(contentsOf: url) {

            struct RawCourse: Decodable {
                let name: String
                let club_name: String
                let address: String
                let city: String
                let state: String
                let latitude: Double
                let longitude: Double
                let holes: Int
                let par: Int
            }

            if let raw = try? JSONDecoder().decode([RawCourse].self, from: data) {
                courses = raw.map { r in
                    Course(
                        id: UUID().uuidString,
                        name: r.name,
                        address: r.address,
                        city: r.city,
                        state: r.state,
                        phone: "",
                        holes: r.holes,
                        par: r.par,
                        latitude: r.latitude,
                        longitude: r.longitude,
                        distanceFromChicago: Course.distanceFromChicago(latitude: r.latitude, longitude: r.longitude)
                    )
                }
            } else {
                print("[CourseService] Failed to decode courses.json")
            }
        } else {
            print("[CourseService] courses.json not found")
        }

        // Merge hardcoded Chicago courses (deduplicate by name+city)
        let existingKeys = Set(courses.map { "\($0.name.lowercased())|\($0.city.lowercased())" })
        for course in chicagoPublicCourses {
            let key = "\(course.name.lowercased())|\(course.city.lowercased())"
            if !existingKeys.contains(key) {
                courses.append(course)
            }
        }

        return courses
    }()

    /// Public courses within 30 miles of Chicago, sorted by distance
    static let chicagoAreaCourses: [Course] = {
        allCourses
            .filter { $0.distanceFromChicago <= 30.0 }
            .sorted { $0.distanceFromChicago < $1.distanceFromChicago }
    }()

    /// Courses within a given radius of a location, sorted by distance
    static func nearbyCourses(from location: CLLocation, radius: Double = 30.0) -> [Course] {
        allCourses
            .filter { $0.distance(from: location) <= radius }
            .sorted { $0.distance(from: location) < $1.distance(from: location) }
    }

    // MARK: - Hardcoded Fallback (original 20 Chicago-area courses)

    static let chicagoPublicCourses: [Course] = [
        Course(
            id: UUID().uuidString, name: "Jackson Park Golf Course",
            address: "6401 S Richards Dr", city: "Chicago", state: "IL",
            phone: "(773) 667-0524", holes: 18, par: 70,
            latitude: 41.7740, longitude: -87.5805, distanceFromChicago: 7.2
        ),
        Course(
            id: UUID().uuidString, name: "Sydney R. Marovitz Golf Course",
            address: "3600 N Recreation Dr", city: "Chicago", state: "IL",
            phone: "(312) 245-0909", holes: 9, par: 36,
            latitude: 41.9470, longitude: -87.6380, distanceFromChicago: 3.8
        ),
        Course(
            id: UUID().uuidString, name: "South Shore Golf Course",
            address: "7059 S South Shore Dr", city: "Chicago", state: "IL",
            phone: "(773) 256-0986", holes: 9, par: 33,
            latitude: 41.7660, longitude: -87.5660, distanceFromChicago: 8.5
        ),
        Course(
            id: UUID().uuidString, name: "Robert A. Black Golf Course",
            address: "2045 W Pratt Blvd", city: "Chicago", state: "IL",
            phone: "(312) 742-7931", holes: 9, par: 33,
            latitude: 42.0010, longitude: -87.6810, distanceFromChicago: 6.1
        ),
        Course(
            id: UUID().uuidString, name: "Columbus Park Golf Course",
            address: "5701 W Jackson Blvd", city: "Chicago", state: "IL",
            phone: "(312) 746-5573", holes: 9, par: 34,
            latitude: 41.8773, longitude: -87.7695, distanceFromChicago: 6.8
        ),
        Course(
            id: UUID().uuidString, name: "Marquette Park Golf Course",
            address: "6700 S Kedzie Ave", city: "Chicago", state: "IL",
            phone: "(312) 747-2761", holes: 9, par: 36,
            latitude: 41.7720, longitude: -87.7020, distanceFromChicago: 8.3
        ),
        Course(
            id: UUID().uuidString, name: "Billy Caldwell Golf Course",
            address: "6150 N Caldwell Ave", city: "Chicago", state: "IL",
            phone: "(312) 792-1930", holes: 9, par: 35,
            latitude: 41.9930, longitude: -87.7600, distanceFromChicago: 9.4
        ),
        Course(
            id: UUID().uuidString, name: "Harborside International Golf Center",
            address: "11001 S Doty Ave E", city: "Chicago", state: "IL",
            phone: "(312) 782-7837", holes: 18, par: 72,
            latitude: 41.6880, longitude: -87.6060, distanceFromChicago: 12.4
        ),
        Course(
            id: UUID().uuidString, name: "Joe Louis (The Chick Evans) Golf Course",
            address: "13100 S Halsted St", city: "Riverdale", state: "IL",
            phone: "(708) 849-0202", holes: 18, par: 72,
            latitude: 41.6340, longitude: -87.6420, distanceFromChicago: 17.5
        ),
        Course(
            id: UUID().uuidString, name: "Glenwoodie Golf Course",
            address: "19301 S State St", city: "Glenwood", state: "IL",
            phone: "(708) 758-1212", holes: 18, par: 72,
            latitude: 41.5360, longitude: -87.6030, distanceFromChicago: 24.1
        ),
        Course(
            id: UUID().uuidString, name: "George W. Dunne National Golf Course",
            address: "16310 S Central Ave", city: "Oak Forest", state: "IL",
            phone: "(708) 429-6886", holes: 18, par: 72,
            latitude: 41.5910, longitude: -87.7830, distanceFromChicago: 22.5
        ),
        Course(
            id: UUID().uuidString, name: "Meadow Lark Golf Course",
            address: "11599 S Austin Ave", city: "Worth", state: "IL",
            phone: "(708) 385-4453", holes: 9, par: 27,
            latitude: 41.6890, longitude: -87.7870, distanceFromChicago: 14.7
        ),
        Course(
            id: UUID().uuidString, name: "River Oaks Golf Course",
            address: "159 Thatcher Ave", city: "Calumet City", state: "IL",
            phone: "(708) 868-4440", holes: 18, par: 70,
            latitude: 41.6148, longitude: -87.5570, distanceFromChicago: 19.0
        ),
        Course(
            id: UUID().uuidString, name: "Fresh Meadow Golf Course",
            address: "2402 Mannheim Rd", city: "Hillside", state: "IL",
            phone: "(708) 449-3434", holes: 9, par: 33,
            latitude: 41.8673, longitude: -87.8922, distanceFromChicago: 12.0
        ),
        Course(
            id: UUID().uuidString, name: "Cog Hill Golf & Country Club (Course 1)",
            address: "12294 Archer Ave", city: "Lemont", state: "IL",
            phone: "(866) 264-4455", holes: 18, par: 71,
            latitude: 41.6780, longitude: -87.9330, distanceFromChicago: 25.3
        ),
        Course(
            id: UUID().uuidString, name: "Indian Boundary Golf Course",
            address: "8600 W Forest Preserve Dr", city: "Chicago", state: "IL",
            phone: "(773) 625-9630", holes: 18, par: 70,
            latitude: 41.9424, longitude: -87.8380, distanceFromChicago: 10.0
        ),
        Course(
            id: UUID().uuidString, name: "Edgebrook Golf Course",
            address: "6100 N Central Ave", city: "Chicago", state: "IL",
            phone: "(312) 792-1930", holes: 18, par: 71,
            latitude: 41.9960, longitude: -87.7640, distanceFromChicago: 9.7
        ),
        Course(
            id: UUID().uuidString, name: "Highland Park Golf Course",
            address: "1201 Park Ave W", city: "Highland Park", state: "IL",
            phone: "(847) 433-9015", holes: 9, par: 33,
            latitude: 42.1840, longitude: -87.8070, distanceFromChicago: 24.0
        ),
        Course(
            id: UUID().uuidString, name: "Weber Park Golf Course",
            address: "9300 Weber Park Pl", city: "Skokie", state: "IL",
            phone: "(847) 674-1500", holes: 9, par: 27,
            latitude: 42.0290, longitude: -87.7280, distanceFromChicago: 10.1
        ),
        Course(
            id: UUID().uuidString, name: "Wilmette Golf Course",
            address: "3900 Fairway Dr", city: "Wilmette", state: "IL",
            phone: "(847) 256-9777", holes: 9, par: 34,
            latitude: 42.0680, longitude: -87.7310, distanceFromChicago: 12.8
        ),
    ]
}
