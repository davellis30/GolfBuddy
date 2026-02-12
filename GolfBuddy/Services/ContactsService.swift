import Foundation
import Contacts

class ContactsService {
    static let shared = ContactsService()

    private let store = CNContactStore()

    private init() {}

    enum ContactsAccessStatus {
        case authorized
        case denied
        case notDetermined
    }

    var accessStatus: ContactsAccessStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    func requestAccess() async -> Bool {
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    func fetchContacts() -> [CNContact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]

        var results: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                results.append(contact)
            }
        } catch {
            // Return empty on failure
        }

        return results
    }

    struct UnmatchedContact: Identifiable {
        let id = UUID()
        let name: String
        let email: String?
    }

    func matchContacts(against users: [User]) -> (matched: [User], unmatched: [UnmatchedContact]) {
        let contacts = fetchContacts()
        let userEmailMap = Dictionary(uniqueKeysWithValues: users.map { ($0.email.lowercased(), $0) })

        var matched: [User] = []
        var matchedIds: Set<UUID> = []
        var unmatched: [UnmatchedContact] = []

        for contact in contacts {
            let fullName = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            guard !fullName.isEmpty else { continue }

            let emails = contact.emailAddresses.map { $0.value as String }
            var didMatch = false

            for email in emails {
                if let user = userEmailMap[email.lowercased()], !matchedIds.contains(user.id) {
                    matched.append(user)
                    matchedIds.insert(user.id)
                    didMatch = true
                    break
                }
            }

            if !didMatch {
                unmatched.append(UnmatchedContact(
                    name: fullName,
                    email: emails.first
                ))
            }
        }

        return (matched, unmatched)
    }
}
