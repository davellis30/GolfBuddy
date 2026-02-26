import SwiftUI

struct SignInWithGoogleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                GoogleLogo()
                    .frame(width: 18, height: 18)

                Text("Sign in with Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.darkText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.mutedText.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

private struct GoogleLogo: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Blue (right arc)
            var blue = Path()
            blue.addArc(center: CGPoint(x: w * 0.5, y: h * 0.5), radius: w * 0.45,
                        startAngle: .degrees(-45), endAngle: .degrees(10), clockwise: false)
            blue.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
            blue.closeSubpath()
            context.fill(blue, with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))

            // Green (bottom arc)
            var green = Path()
            green.addArc(center: CGPoint(x: w * 0.5, y: h * 0.5), radius: w * 0.45,
                         startAngle: .degrees(10), endAngle: .degrees(120), clockwise: false)
            green.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
            green.closeSubpath()
            context.fill(green, with: .color(Color(red: 0.20, green: 0.66, blue: 0.33)))

            // Yellow (left-bottom arc)
            var yellow = Path()
            yellow.addArc(center: CGPoint(x: w * 0.5, y: h * 0.5), radius: w * 0.45,
                          startAngle: .degrees(120), endAngle: .degrees(215), clockwise: false)
            yellow.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(Color(red: 0.98, green: 0.74, blue: 0.02)))

            // Red (top-left arc)
            var red = Path()
            red.addArc(center: CGPoint(x: w * 0.5, y: h * 0.5), radius: w * 0.45,
                       startAngle: .degrees(215), endAngle: .degrees(315), clockwise: false)
            red.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
            red.closeSubpath()
            context.fill(red, with: .color(Color(red: 0.92, green: 0.26, blue: 0.21)))

            // White center
            let inset = w * 0.22
            let innerRect = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
            context.fill(Path(ellipseIn: innerRect), with: .color(.white))

            // Blue horizontal bar (the "G" crossbar)
            let barRect = CGRect(x: w * 0.5, y: h * 0.38, width: w * 0.42, height: h * 0.24)
            context.fill(Path(barRect), with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))
        }
    }
}
