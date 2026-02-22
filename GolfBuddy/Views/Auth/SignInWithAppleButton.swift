import SwiftUI
import AuthenticationServices

struct SignInWithAppleButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onComplete: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButtonRepresentable(
            style: colorScheme == .dark ? .white : .black,
            onComplete: onComplete
        )
        .id(colorScheme)
        .frame(height: 50)
        .cornerRadius(12)
    }
}

struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let style: ASAuthorizationAppleIDButton.Style
    let onComplete: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: style)
        button.cornerRadius = 12
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleTap),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onComplete: (Result<ASAuthorization, Error>) -> Void

        init(onComplete: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onComplete = onComplete
        }

        @objc func handleTap() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithAuthorization authorization: ASAuthorization
        ) {
            onComplete(.success(authorization))
        }

        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithError error: Error
        ) {
            onComplete(.failure(error))
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else {
                return UIWindow()
            }
            return window
        }
    }
}
