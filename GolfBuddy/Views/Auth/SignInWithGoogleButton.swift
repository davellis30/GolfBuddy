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
            let center = CGPoint(x: w * 0.5, y: h * 0.5)
            let outerR = w * 0.48
            let innerR = w * 0.28
            let strokeW = outerR - innerR

            // Red (top-left quadrant, from 7 o'clock to 12 o'clock)
            var red = Path()
            red.addArc(center: center, radius: outerR - strokeW / 2,
                       startAngle: .degrees(150), endAngle: .degrees(270), clockwise: false)
            context.stroke(red, with: .color(Color(red: 0.92, green: 0.26, blue: 0.21)),
                          lineWidth: strokeW)

            // Yellow (bottom-left, from 5 o'clock to 7 o'clock)
            var yellow = Path()
            yellow.addArc(center: center, radius: outerR - strokeW / 2,
                          startAngle: .degrees(90), endAngle: .degrees(150), clockwise: false)
            context.stroke(yellow, with: .color(Color(red: 0.98, green: 0.74, blue: 0.02)),
                          lineWidth: strokeW)

            // Green (bottom-right, from 3 o'clock to 5 o'clock)
            var green = Path()
            green.addArc(center: center, radius: outerR - strokeW / 2,
                         startAngle: .degrees(30), endAngle: .degrees(90), clockwise: false)
            context.stroke(green, with: .color(Color(red: 0.20, green: 0.66, blue: 0.33)),
                          lineWidth: strokeW)

            // Blue (right side, from 12 o'clock to 3 o'clock)
            var blue = Path()
            blue.addArc(center: center, radius: outerR - strokeW / 2,
                        startAngle: .degrees(-30), endAngle: .degrees(30), clockwise: false)
            context.stroke(blue, with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)),
                          lineWidth: strokeW)

            // Blue crossbar extending right from center
            let barY = center.y - strokeW / 2
            let barRect = CGRect(x: center.x - strokeW * 0.1, y: barY,
                                 width: outerR + strokeW * 0.1, height: strokeW)
            context.fill(Path(barRect), with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))

            // Clean up the top-right to make the "G" opening
            var topClear = Path()
            topClear.move(to: CGPoint(x: center.x, y: 0))
            topClear.addLine(to: CGPoint(x: w, y: 0))
            topClear.addLine(to: CGPoint(x: w, y: barY))
            topClear.addLine(to: CGPoint(x: center.x + innerR, y: barY))
            topClear.addArc(center: center, radius: innerR,
                           startAngle: .degrees(-30), endAngle: .degrees(-90), clockwise: true)
            topClear.closeSubpath()
            context.fill(topClear, with: .color(.white))
        }
    }
}
