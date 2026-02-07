import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let primaryGreen = Color(red: 0.13, green: 0.37, blue: 0.15)
    static let accentGreen = Color(red: 0.18, green: 0.54, blue: 0.22)
    static let lightGreen = Color(red: 0.56, green: 0.74, blue: 0.46)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let darkCream = Color(red: 0.91, green: 0.88, blue: 0.79)
    static let darkText = Color(red: 0.15, green: 0.15, blue: 0.12)
    static let mutedText = Color(red: 0.45, green: 0.45, blue: 0.40)
    static let statusLooking = Color(red: 0.20, green: 0.60, blue: 0.86)
    static let statusPlaying = Color(red: 0.18, green: 0.54, blue: 0.22)
    static let statusSeeking = Color(red: 0.90, green: 0.62, blue: 0.15)

    // MARK: - Fonts
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 13, weight: .medium, design: .rounded)
}

// MARK: - Reusable Modifiers

struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.bodyFont.weight(.semibold))
            .foregroundColor(AppTheme.cream)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.accentGreen)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.bodyFont.weight(.semibold))
            .foregroundColor(AppTheme.accentGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.accentGreen, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
