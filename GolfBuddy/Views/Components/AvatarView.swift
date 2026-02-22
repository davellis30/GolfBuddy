import SwiftUI

struct AvatarView: View {
    @EnvironmentObject var dataService: DataService
    let userId: String
    var size: CGFloat = 48

    var body: some View {
        if let photoData = dataService.profilePhotos[userId],
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if let user = dataService.allUsers.first(where: { $0.id == userId }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.lightGreen, AppTheme.accentGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                Text(user.avatarInitials)
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .task(id: userId) {
                dataService.loadProfilePhoto(for: userId)
            }
        } else {
            Circle()
                .fill(AppTheme.darkCream)
                .frame(width: size, height: size)
        }
    }
}
