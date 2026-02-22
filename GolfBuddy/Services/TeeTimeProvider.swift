import Foundation

protocol TeeTimeProvider {
    func searchTeeTimes(request: TeeTimeSearchRequest) async throws -> [TeeTimeSearchResult]
}
