import Foundation

struct CourseService {
    /// Public golf courses within ~30 miles of downtown Chicago
    static let chicagoPublicCourses: [Course] = [
        Course(
            id: UUID(), name: "Jackson Park Golf Course",
            address: "6401 S Richards Dr", city: "Chicago",
            phone: "(773) 667-0524", holes: 18, par: 70,
            latitude: 41.7740, longitude: -87.5805, distanceFromChicago: 7.2
        ),
        Course(
            id: UUID(), name: "Sydney R. Marovitz Golf Course",
            address: "3600 N Recreation Dr", city: "Chicago",
            phone: "(312) 245-0909", holes: 9, par: 36,
            latitude: 41.9470, longitude: -87.6380, distanceFromChicago: 3.8
        ),
        Course(
            id: UUID(), name: "South Shore Golf Course",
            address: "7059 S South Shore Dr", city: "Chicago",
            phone: "(773) 256-0986", holes: 9, par: 33,
            latitude: 41.7660, longitude: -87.5660, distanceFromChicago: 8.5
        ),
        Course(
            id: UUID(), name: "Robert A. Black Golf Course",
            address: "2045 W Pratt Blvd", city: "Chicago",
            phone: "(312) 742-7931", holes: 9, par: 33,
            latitude: 42.0010, longitude: -87.6810, distanceFromChicago: 6.1
        ),
        Course(
            id: UUID(), name: "Columbus Park Golf Course",
            address: "5701 W Jackson Blvd", city: "Chicago",
            phone: "(312) 746-5573", holes: 9, par: 34,
            latitude: 41.8773, longitude: -87.7695, distanceFromChicago: 6.8
        ),
        Course(
            id: UUID(), name: "Marquette Park Golf Course",
            address: "6700 S Kedzie Ave", city: "Chicago",
            phone: "(312) 747-2761", holes: 9, par: 36,
            latitude: 41.7720, longitude: -87.7020, distanceFromChicago: 8.3
        ),
        Course(
            id: UUID(), name: "Billy Caldwell Golf Course",
            address: "6150 N Caldwell Ave", city: "Chicago",
            phone: "(312) 792-1930", holes: 9, par: 35,
            latitude: 41.9930, longitude: -87.7600, distanceFromChicago: 9.4
        ),
        Course(
            id: UUID(), name: "Harborside International Golf Center",
            address: "11001 S Doty Ave E", city: "Chicago",
            phone: "(312) 782-7837", holes: 18, par: 72,
            latitude: 41.6880, longitude: -87.6060, distanceFromChicago: 12.4
        ),
        Course(
            id: UUID(), name: "Joe Louis (The Chick Evans) Golf Course",
            address: "13100 S Halsted St", city: "Riverdale",
            phone: "(708) 849-0202", holes: 18, par: 72,
            latitude: 41.6340, longitude: -87.6420, distanceFromChicago: 17.5
        ),
        Course(
            id: UUID(), name: "Glenwoodie Golf Course",
            address: "19301 S State St", city: "Glenwood",
            phone: "(708) 758-1212", holes: 18, par: 72,
            latitude: 41.5360, longitude: -87.6030, distanceFromChicago: 24.1
        ),
        Course(
            id: UUID(), name: "George W. Dunne National Golf Course",
            address: "16310 S Central Ave", city: "Oak Forest",
            phone: "(708) 429-6886", holes: 18, par: 72,
            latitude: 41.5910, longitude: -87.7830, distanceFromChicago: 22.5
        ),
        Course(
            id: UUID(), name: "Meadow Lark Golf Course",
            address: "11599 S Austin Ave", city: "Worth",
            phone: "(708) 385-4453", holes: 9, par: 27,
            latitude: 41.6890, longitude: -87.7870, distanceFromChicago: 14.7
        ),
        Course(
            id: UUID(), name: "River Oaks Golf Course",
            address: "159 Thatcher Ave", city: "Calumet City",
            phone: "(708) 868-4440", holes: 18, par: 70,
            latitude: 41.6148, longitude: -87.5570, distanceFromChicago: 19.0
        ),
        Course(
            id: UUID(), name: "Fresh Meadow Golf Course",
            address: "2402 Mannheim Rd", city: "Hillside",
            phone: "(708) 449-3434", holes: 9, par: 33,
            latitude: 41.8673, longitude: -87.8922, distanceFromChicago: 12.0
        ),
        Course(
            id: UUID(), name: "Cog Hill Golf & Country Club (Course 1)",
            address: "12294 Archer Ave", city: "Lemont",
            phone: "(866) 264-4455", holes: 18, par: 71,
            latitude: 41.6780, longitude: -87.9330, distanceFromChicago: 25.3
        ),
        Course(
            id: UUID(), name: "Indian Boundary Golf Course",
            address: "8600 W Forest Preserve Dr", city: "Chicago",
            phone: "(773) 625-9630", holes: 18, par: 70,
            latitude: 41.9424, longitude: -87.8380, distanceFromChicago: 10.0
        ),
        Course(
            id: UUID(), name: "Edgebrook Golf Course",
            address: "6100 N Central Ave", city: "Chicago",
            phone: "(312) 792-1930", holes: 18, par: 71,
            latitude: 41.9960, longitude: -87.7640, distanceFromChicago: 9.7
        ),
        Course(
            id: UUID(), name: "Highland Park Golf Course",
            address: "1201 Park Ave W", city: "Highland Park",
            phone: "(847) 433-9015", holes: 9, par: 33,
            latitude: 42.1840, longitude: -87.8070, distanceFromChicago: 24.0
        ),
        Course(
            id: UUID(), name: "Weber Park Golf Course",
            address: "9300 Weber Park Pl", city: "Skokie",
            phone: "(847) 674-1500", holes: 9, par: 27,
            latitude: 42.0290, longitude: -87.7280, distanceFromChicago: 10.1
        ),
        Course(
            id: UUID(), name: "Wilmette Golf Course",
            address: "3900 Fairway Dr", city: "Wilmette",
            phone: "(847) 256-9777", holes: 9, par: 34,
            latitude: 42.0680, longitude: -87.7310, distanceFromChicago: 12.8
        ),
    ]
}
