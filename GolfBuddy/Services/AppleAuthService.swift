import Foundation
import AuthenticationServices

class AppleAuthService: ObservableObject {
    static let shared = AppleAuthService()

    @Published var currentAppleUserId: String?

    private let storedAppleIdKey = "storedAppleUserId"

    private init() {
        loadStoredAppleId()
    }

    // MARK: - Persistence

    func saveAppleId(_ appleUserId: String) {
        currentAppleUserId = appleUserId
        UserDefaults.standard.set(appleUserId, forKey: storedAppleIdKey)
    }

    func loadStoredAppleId() {
        currentAppleUserId = UserDefaults.standard.string(forKey: storedAppleIdKey)
    }

    func clearStoredAppleId() {
        currentAppleUserId = nil
        UserDefaults.standard.removeObject(forKey: storedAppleIdKey)
    }

    // MARK: - Credential Validation

    func checkCredentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        do {
            return try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
        } catch {
            print("[AppleAuthService] Failed to check credential state: \(error)")
            return .notFound
        }
    }
}
