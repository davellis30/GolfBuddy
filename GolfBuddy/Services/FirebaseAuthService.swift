import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

class FirebaseAuthService {
    static let shared = FirebaseAuthService()

    private let db = Firestore.firestore()
    private let usersCollection = "users"

    private init() {}

    // MARK: - Email/Password Auth

    func signUp(email: String, password: String, username: String, displayName: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let user = User(
            id: uid,
            username: username,
            displayName: displayName,
            email: email,
            handicap: nil,
            homeCourse: nil
        )

        try await saveUserProfile(user)
        return user
    }

    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return try await loadUserProfile(firebaseUserId: result.user.uid)
    }

    // MARK: - Apple Sign In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Apple identity token"])
        }

        let oauthCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nil,
            fullName: credential.fullName
        )

        let result = try await Auth.auth().signIn(with: oauthCredential)
        let uid = result.user.uid

        // Check if user profile already exists
        if let existingUser = try? await loadUserProfile(firebaseUserId: uid) {
            return existingUser
        }

        // Create new profile for first-time Apple sign-in
        let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let user = User(
            id: uid,
            username: "apple_\(UUID().uuidString.prefix(8))",
            displayName: displayName.isEmpty ? "Apple User" : displayName,
            email: credential.email ?? result.user.email ?? "",
            handicap: nil,
            homeCourse: nil
        )

        try await saveUserProfile(user)
        return user
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        try await user.delete()
    }

    // MARK: - Firestore Profile

    func loadUserProfile(firebaseUserId: String) async throws -> User {
        let doc = try await db.collection(usersCollection).document(firebaseUserId).getDocument()
        guard let data = doc.data() else {
            throw NSError(domain: "FirebaseAuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }

        return User(
            id: firebaseUserId,
            username: data["username"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            email: data["email"] as? String ?? "",
            handicap: data["handicap"] as? Double,
            homeCourse: data["homeCourse"] as? String
        )
    }

    func updateUserProfile(firebaseUserId: String, handicap: Double?, homeCourse: String?) async throws {
        var fields: [String: Any] = [:]
        if let handicap = handicap {
            fields["handicap"] = handicap
        } else {
            fields["handicap"] = FieldValue.delete()
        }
        if let homeCourse = homeCourse {
            fields["homeCourse"] = homeCourse
        } else {
            fields["homeCourse"] = FieldValue.delete()
        }

        try await db.collection(usersCollection).document(firebaseUserId).updateData(fields)
    }

    private func saveUserProfile(_ user: User) async throws {
        var data: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "displayName": user.displayName,
            "email": user.email,
            "usernameLower": user.username.lowercased(),
            "displayNameLower": user.displayName.lowercased()
        ]
        if let handicap = user.handicap {
            data["handicap"] = handicap
        }
        if let homeCourse = user.homeCourse {
            data["homeCourse"] = homeCourse
        }

        try await db.collection(usersCollection).document(user.id).setData(data)
    }
}
