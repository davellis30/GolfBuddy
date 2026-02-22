import SwiftUI
import CoreLocation

struct CourseSelectionRow: View {
    let course: Course
    let isSelected: Bool
    let isFavorite: Bool
    var userLocation: CLLocation?
    let onToggle: () -> Void
    let onFavoriteToggle: () -> Void

    private var displayDistance: String {
        if let location = userLocation {
            return course.formattedDistance(from: location)
        }
        return course.formattedDistance
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.accentGreen : AppTheme.mutedText)
                    .font(.system(size: 22))

                // Course info
                VStack(alignment: .leading, spacing: 3) {
                    Text(course.name)
                        .font(AppTheme.bodyFont.weight(.medium))
                        .foregroundColor(AppTheme.darkText)
                        .lineLimit(1)
                    Text("\(course.city) · \(displayDistance)")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                }

                Spacer()

                // Favorite star
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? AppTheme.gold : AppTheme.mutedText.opacity(0.5))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppTheme.accentGreen.opacity(0.08) : Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? AppTheme.accentGreen.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
