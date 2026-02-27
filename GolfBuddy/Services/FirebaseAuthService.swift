import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn

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

    // MARK: - Google Sign In

    func signInWithGoogle(presenting viewController: UIViewController) async throws -> User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID"])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token"])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let uid = authResult.user.uid

        // Check if user profile already exists
        if let existingUser = try? await loadUserProfile(firebaseUserId: uid) {
            return existingUser
        }

        // Create new profile for first-time Google sign-in
        let user = User(
            id: uid,
            username: "google_\(UUID().uuidString.prefix(8))",
            displayName: result.user.profile?.name ?? "Google User",
            email: result.user.profile?.email ?? authResult.user.email ?? "",
            handicap: nil,
            homeCourse: nil
        )

        try await saveUserProfile(user)
        return user
    }

    // MARK: - Email Verification & Password Reset

    var isEmailVerified: Bool {
        Auth.auth().currentUser?.isEmailVerified ?? false
    }

    func sendEmailVerification() async throws {
        try await Auth.auth().currentUser?.sendEmailVerification()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func reloadUser() async throws {
        try await Auth.auth().currentUser?.reload()
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
            homeCourse: data["homeCourse"] as? String,
            profilePhotoUrl: data["profilePhotoUrl"] as? String
        )
    }

    func updateUserProfile(firebaseUserId: String, handicap: Double?, homeCourse: String?, cardColorTheme: String?, statusTagline: String?) async throws {
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
        if let cardColorTheme = cardColorTheme {
            fields["cardColorTheme"] = cardColorTheme
        } else {
            fields["cardColorTheme"] = FieldValue.delete()
        }
        if let statusTagline = statusTagline, !statusTagline.isEmpty {
            fields["statusTagline"] = statusTagline
        } else {
            fields["statusTagline"] = FieldValue.delete()
        }

        try await db.collection(usersCollection).document(firebaseUserId).updateData(fields)
    }

    func updateStatusTagline(firebaseUserId: String, tagline: String) async throws {
        if tagline.isEmpty {
            try await db.collection(usersCollection).document(firebaseUserId).updateData([
                "statusTagline": FieldValue.delete()
            ])
        } else {
            try await db.collection(usersCollection).document(firebaseUserId).updateData([
                "statusTagline": tagline
            ])
        }
    }

    func updateProfilePhotoUrl(firebaseUserId: String, url: String?) async throws {
        if let url = url {
            try await db.collection(usersCollection).document(firebaseUserId).updateData([
                "profilePhotoUrl": url
            ])
        } else {
            try await db.collection(usersCollection).document(firebaseUserId).updateData([
                "profilePhotoUrl": FieldValue.delete()
            ])
        }
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
        if let profilePhotoUrl = user.profilePhotoUrl {
            data["profilePhotoUrl"] = profilePhotoUrl
        }

        try await db.collection(usersCollection).document(user.id).setData(data)
    }
}
