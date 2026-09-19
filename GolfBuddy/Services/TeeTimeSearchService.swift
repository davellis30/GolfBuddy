import Foundation

class TeeTimeSearchService: ObservableObject {
    enum SearchState {
        case idle
        case searching
        case results
        case error(String)
    }

    @Published var searchState: SearchState = .idle
    @Published var results: [TeeTimeSearchResult] = []
    @Published var favoriteCourseIds: Set<String> = []
    /// Inventory source from the last search ("mock", "lightspeed", ...).
    /// Nil when the mock provider is in use.
    @Published var inventorySource: String?

    private let provider: TeeTimeProvider
    private static let favoritesKey = "favoriteCourseIds"

    init(provider: TeeTimeProvider = APITeeTimeProvider()) {
        self.provider = provider
        loadFavorites()
    }

    @MainActor
    func search(request: TeeTimeSearchRequest) async {
        searchState = .searching
        results = []
        inventorySource = nil

        do {
            let searchResults = try await provider.searchTeeTimes(request: request)
            results = searchResults
            inventorySource = (provider as? APITeeTimeProvider)?.providerName
            searchState = .results
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? "Search failed. Please try again."
            searchState = .error(message)
        }
    }

    // MARK: - Favorites

    func toggleFavorite(_ courseId: String) {
        if favoriteCourseIds.contains(courseId) {
            favoriteCourseIds.remove(courseId)
        } else {
            favoriteCourseIds.insert(courseId)
        }
        saveFavorites()
    }

    func isFavorite(_ courseId: String) -> Bool {
        favoriteCourseIds.contains(courseId)
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: Self.favoritesKey) as? [String] {
            favoriteCourseIds = Set(saved)
        }
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteCourseIds), forKey: Self.favoritesKey)
    }
}
