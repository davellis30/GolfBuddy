import Foundation
import FirebaseAuth

/// `TeeTimeProvider` backed by the CalendarCaddy API (the `api` Cloud Function).
///
/// Drop-in replacement for `MockTeeTimeProvider`: same protocol, live backend.
/// The API base URL comes from the `CalendarCaddyAPIBaseURL` Info.plist key,
/// e.g. `https://us-central1-myproject.cloudfunctions.net/api`.
///
/// Auth: the signed-in user's Firebase ID token is sent as
/// `Authorization: Bearer`. Every response names its inventory `provider`
/// ("mock" until a vendor partnership is live) — surfaced via `providerName`
/// so the UI can label demo data honestly.
class APITeeTimeProvider: TeeTimeProvider {

    enum APIError: Error, LocalizedError {
        case notConfigured
        case transport(Error)
        case server(status: Int, message: String?)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Tee-time search isn't set up yet. Add your CalendarCaddyAPIBaseURL to Info.plist after deploying the API."
            case .transport:
                return "Couldn't reach the tee-time service. Check your connection and try again."
            case .server(let status, let message):
                if status == 401 {
                    return "Please sign in to search tee times."
                }
                return message ?? "Tee-time search failed (server error \(status))."
            case .decoding:
                return "Tee-time search returned an unexpected response."
            }
        }
    }

    /// Inventory source from the last search ("mock", "lightspeed", ...).
    private(set) var providerName: String?

    private let baseURL: URL?
    private let session: URLSession
    private let isoFormatter = ISO8601DateFormatter()

    init(session: URLSession = .shared) {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "CalendarCaddyAPIBaseURL") as? String,
           !raw.isEmpty,
           let url = URL(string: raw) {
            self.baseURL = url
        } else {
            self.baseURL = nil
        }
        self.session = session
    }

    func searchTeeTimes(request: TeeTimeSearchRequest) async throws -> [TeeTimeSearchResult] {
        guard let baseURL else {
            throw APIError.notConfigured
        }

        let body = SearchRequestBody(
            courses: request.courses.map {
                SearchRequestBody.CourseRef(id: $0.id, name: $0.name, holes: $0.holes)
            },
            date: ChicagoTime.dayString(from: request.date),
            earliestTime: ChicagoTime.timeString(from: request.earliestTime),
            latestTime: ChicagoTime.timeString(from: request.latestTime),
            players: request.numberOfPlayers
        )

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("v1/teetimes/search"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(body)

        if let token = try await Auth.auth().currentUser?.getIDToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error
            throw APIError.server(status: http.statusCode, message: message)
        }

        let decoded: SearchResponse
        do {
            decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }

        providerName = decoded.provider

        let coursesById = Dictionary(uniqueKeysWithValues: request.courses.map { ($0.id, $0) })
        return decoded.results.compactMap { result in
            guard let course = coursesById[result.courseId] else { return nil }
            let teeTimes = result.teeTimes.compactMap { dto -> TeeTime? in
                guard let date = isoFormatter.date(from: dto.date) else { return nil }
                return TeeTime(
                    id: dto.id,
                    courseId: dto.courseId,
                    courseName: dto.courseName,
                    date: date,
                    availableSlots: dto.availableSlots,
                    pricePerPlayer: dto.pricePerPlayer,
                    holes: dto.holes,
                    isHotDeal: dto.isHotDeal
                )
            }
            .sorted { $0.date < $1.date }
            return TeeTimeSearchResult(
                id: result.courseId,
                course: course,
                teeTimes: teeTimes,
                searchedAt: Date()
            )
        }
    }
}

// MARK: - DTOs

private struct SearchRequestBody: Encodable {
    struct CourseRef: Encodable {
        let id: String
        let name: String
        let holes: Int
    }
    let courses: [CourseRef]
    let date: String
    let earliestTime: String
    let latestTime: String
    let players: Int
}

private struct SearchResponse: Decodable {
    let provider: String
    let searchedAt: String
    let results: [CourseResult]

    struct CourseResult: Decodable {
        let courseId: String
        let courseName: String
        let teeTimes: [TeeTimeDTO]
    }

    struct TeeTimeDTO: Decodable {
        let id: String
        let courseId: String
        let courseName: String
        let date: String
        let availableSlots: Int
        let pricePerPlayer: Double
        let holes: Int
        let isHotDeal: Bool
    }
}

private struct ErrorBody: Decodable {
    let error: String?
}

// MARK: - Chicago-local formatting

private enum ChicagoTime {
    static var timeZone: TimeZone {
        TimeZone(identifier: "America/Chicago") ?? .current
    }

    static func dayString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = timeZone
        return f.string(from: date)
    }

    static func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = timeZone
        return f.string(from: date)
    }
}
