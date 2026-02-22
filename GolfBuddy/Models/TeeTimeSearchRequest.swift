import Foundation

struct TeeTimeSearchRequest {
    let courses: [Course]
    let date: Date
    let earliestTime: Date
    let latestTime: Date
    let numberOfPlayers: Int
}
