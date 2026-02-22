import SwiftUI

struct TeeTimeCard: View {
    let teeTime: TeeTime

    var body: some View {
        HStack(spacing: 14) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(teeTime.formattedTime)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.darkText)
                Text("\(teeTime.holes)H")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(teeTime.holes == 18 ? AppTheme.accentGreen : AppTheme.lightGreen)
                    )
            }
            .frame(width: 80, alignment: .leading)

            // Price and slots
            VStack(alignment: .leading, spacing: 2) {
                Text(teeTime.formattedPrice)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(teeTime.isHotDeal ? AppTheme.statusSeeking : AppTheme.primaryGreen)
                Text("\(teeTime.availableSlots) of 4 spots")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            // Hot deal badge
            if teeTime.isHotDeal {
                Text("HOT DEAL")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.gold)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.subtleShadow, radius: 4, x: 0, y: 2)
        )
    }
}
