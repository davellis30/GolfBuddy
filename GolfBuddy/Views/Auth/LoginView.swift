import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var dataService: DataService
    @State private var isSignUp = false
    @State private var username = ""
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    // Logo area
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGreen)
                                .frame(width: 90, height: 90)
                            Image(systemName: "figure.golf")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.onAccent)
                        }

                        Text("GolfBuddy")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primaryGreen)

                        Text("Find your foursome")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.mutedText)
                    }

                    // Form
                    VStack(spacing: 16) {
                        if isSignUp {
                            FormField(icon: "person.fill", placeholder: "Display Name", text: $displayName)
                            FormField(icon: "at", placeholder: "Username", text: $username)
                                .textInputAutocapitalization(.never)
                        }

                        FormField(icon: "envelope.fill", placeholder: "Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                        FormField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                    }
                    .padding(.horizontal, 24)

                    // Actions
                    VStack(spacing: 14) {
                        Button(action: handleSubmit) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                        .buttonStyle(GreenButtonStyle())
                        .disabled(isLoading)

                        Button(action: { withAnimation { isSignUp.toggle() } }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.accentGreen)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign in with Apple
                    VStack(spacing: 14) {
                        HStack {
                            Rectangle()
                                .fill(AppTheme.mutedText.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)
                            Rectangle()
                                .fill(AppTheme.mutedText.opacity(0.3))
                                .frame(height: 1)
                        }

                        SignInWithAppleButtonView { result in
                            handleAppleSignIn(result)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Failed to get Apple ID credential"
                showError = true
                return
            }
            isLoading = true
            Task {
                do {
                    try await dataService.signInWithApple(credential: credential)
                } catch {
                    await MainActor.run {
                        errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                        showError = true
                    }
                }
                await MainActor.run {
                    isLoading = false
                }
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func handleSubmit() {
        isLoading = true
        Task {
            do {
                if isSignUp {
                    guard !username.isEmpty, !displayName.isEmpty, !email.isEmpty, !password.isEmpty else {
                        await MainActor.run {
                            errorMessage = "Please fill in all fields."
                            showError = true
                            isLoading = false
                        }
                        return
                    }
                    try await dataService.signUp(
                        username: username,
                        displayName: displayName,
                        email: email,
                        password: password
                    )
                } else {
                    guard !email.isEmpty, !password.isEmpty else {
                        await MainActor.run {
                            errorMessage = "Please enter your email and password."
                            showError = true
                            isLoading = false
                        }
                        return
                    }
                    try await dataService.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentGreen)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.darkText)
            } else {
                TextField(placeholder, text: $text)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.darkText)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground)
                .shadow(color: AppTheme.subtleShadow, radius: 4, x: 0, y: 2)
        )
    }
}
