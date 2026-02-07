import SwiftUI

struct LoginView: View {
    @EnvironmentObject var dataService: DataService
    @State private var isSignUp = false
    @State private var username = ""
    @State private var displayName = ""
    @State private var email = ""
    @State private var showError = false
    @State private var errorMessage = ""

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
                                .foregroundColor(AppTheme.cream)
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
                            FormField(icon: "envelope.fill", placeholder: "Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }

                        FormField(icon: "at", placeholder: "Username", text: $username)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal, 24)

                    // Actions
                    VStack(spacing: 14) {
                        Button(action: handleSubmit) {
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                        .buttonStyle(GreenButtonStyle())

                        Button(action: { withAnimation { isSignUp.toggle() } }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.accentGreen)
                        }
                    }
                    .padding(.horizontal, 24)

                    if !isSignUp {
                        VStack(spacing: 8) {
                            Text("Demo Accounts")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)

                            HStack(spacing: 8) {
                                ForEach(["mikej", "sarahw", "davepark"], id: \.self) { name in
                                    Button(action: {
                                        username = name
                                        handleSubmit()
                                    }) {
                                        Text("@\(name)")
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(AppTheme.accentGreen)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .stroke(AppTheme.accentGreen, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

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

    private func handleSubmit() {
        if isSignUp {
            guard !username.isEmpty, !displayName.isEmpty, !email.isEmpty else {
                errorMessage = "Please fill in all fields."
                showError = true
                return
            }
            dataService.signUp(username: username, displayName: displayName, email: email)
        } else {
            guard !username.isEmpty else {
                errorMessage = "Please enter your username."
                showError = true
                return
            }
            if !dataService.signIn(username: username) {
                errorMessage = "Username not found. Try a demo account or sign up."
                showError = true
            }
        }
    }
}

struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentGreen)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(AppTheme.bodyFont)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
}
