import Foundation

struct MockTeeTimeProvider: TeeTimeProvider {

    func searchTeeTimes(request: TeeTimeSearchRequest) async throws -> [TeeTimeSearchResult] {
        // Simulate network latency
        try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))

        let calendar = Calendar.current
        let now = Date()

        return request.courses.map { course in
            var rng = SeededRNG(seed: seed(for: course.id, date: request.date))

            var teeTimes: [TeeTime] = []
            var current = request.earliestTime

            while current < request.latestTime {
                let interval = Int.random(in: 7...12, using: &rng)
                current = calendar.date(byAdding: .minute, value: interval, to: current) ?? current

                guard current < request.latestTime else { break }

                let slots = Int.random(in: 1...4, using: &rng)
                guard slots >= request.numberOfPlayers else { continue }

                // ~20% chance of a gap (already booked)
                if Int.random(in: 0...4, using: &rng) == 0 { continue }

                let hour = calendar.component(.hour, from: current)
                let price = priceForHour(hour, using: &rng)
                let isHotDeal = Int.random(in: 0...6, using: &rng) == 0
                let holes = course.holes == 9 ? 9 : (Int.random(in: 0...3, using: &rng) == 0 ? 9 : 18)

                teeTimes.append(TeeTime(
                    id: UUID().uuidString,
                    courseId: course.id,
                    courseName: course.name,
                    date: current,
                    availableSlots: slots,
                    pricePerPlayer: isHotDeal ? price * 0.75 : price,
                    holes: holes,
                    isHotDeal: isHotDeal
                ))
            }

            return TeeTimeSearchResult(
                id: course.id,
                course: course,
                teeTimes: teeTimes.sorted { $0.date < $1.date },
                searchedAt: now
            )
        }
    }

    // MARK: - Helpers

    private func seed(for courseId: String, date: Date) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(courseId)
        hasher.combine(Calendar.current.startOfDay(for: date))
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    private func priceForHour(_ hour: Int, using rng: inout SeededRNG) -> Double {
        switch hour {
        case ..<8:
            return Double.random(in: 35...45, using: &rng)
        case 8..<11:
            return Double.random(in: 55...75, using: &rng)
        case 11..<14:
            return Double.random(in: 45...60, using: &rng)
        case 14..<16:
            return Double.random(in: 40...55, using: &rng)
        default:
            return Double.random(in: 25...35, using: &rng)
        }
    }
}

// MARK: - Seeded Random Number Generator

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
