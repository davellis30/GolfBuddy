import SwiftUI

struct AppTheme {
    // MARK: - Dynamic Colors

    static let primaryGreen = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.52, blue: 0.22, alpha: 1)
            : UIColor(red: 0.13, green: 0.37, blue: 0.15, alpha: 1)
    })

    static let accentGreen = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.70, blue: 0.35, alpha: 1)
            : UIColor(red: 0.18, green: 0.54, blue: 0.22, alpha: 1)
    })

    static let lightGreen = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.65, blue: 0.38, alpha: 1)
            : UIColor(red: 0.56, green: 0.74, blue: 0.46, alpha: 1)
    })

    static let cream = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1)
    })

    static let darkCream = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
            : UIColor(red: 0.91, green: 0.88, blue: 0.79, alpha: 1)
    })

    static let darkText = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.93, blue: 0.90, alpha: 1)
            : UIColor(red: 0.15, green: 0.15, blue: 0.12, alpha: 1)
    })

    static let mutedText = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.62, blue: 0.58, alpha: 1)
            : UIColor(red: 0.45, green: 0.45, blue: 0.40, alpha: 1)
    })

    static let statusLooking = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.70, blue: 0.95, alpha: 1)
            : UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)
    })

    static let statusPlaying = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.70, blue: 0.35, alpha: 1)
            : UIColor(red: 0.18, green: 0.54, blue: 0.22, alpha: 1)
    })

    static let statusSeeking = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1)
            : UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 1)
    })

    static let gold = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.75, blue: 0.20, alpha: 1)
            : UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1)
    })

    // MARK: - Semantic Colors

    static let cardBackground = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            : UIColor.white
    })

    static let inputBackground = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            : UIColor.white
    })

    static let subtleShadow = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.clear
            : UIColor.black.withAlphaComponent(0.06)
    })

    static let receivedBubble = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1)
            : UIColor.systemGray5
    })

    static let onAccent = Color.white

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
            .foregroundColor(AppTheme.onAccent)
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
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentGreen, lineWidth: 2)
                    )
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
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.subtleShadow, radius: 8, x: 0, y: 2)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
