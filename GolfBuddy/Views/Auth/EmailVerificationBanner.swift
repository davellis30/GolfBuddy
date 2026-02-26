import SwiftUI

struct EmailVerificationBanner: View {
    @EnvironmentObject var dataService: DataService
    @State private var showResendConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.primaryGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("Verify your email")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.darkText)
                Text("Check your inbox for a verification link.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            Button("Resend") {
                dataService.sendEmailVerification()
                showResendConfirmation = true
            }
            .font(AppTheme.captionFont)
            .foregroundColor(AppTheme.accentGreen)

            Button {
                withAnimation {
                    dataService.showVerificationBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.mutedText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.subtleShadow, radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .alert("Verification Email Sent", isPresented: $showResendConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A new verification email has been sent to your inbox.")
        }
    }
}
