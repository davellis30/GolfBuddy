import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var handicapText: String = ""
    @State private var selectedCourse: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isSaving = false
    @State private var photoRemoved = false
    @State private var selectedTheme: CardColorTheme = .classicGreen
    @State private var taglineText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile photo
                        if let userId = dataService.currentUser?.id {
                            VStack(spacing: 12) {
                                if let photoData = selectedPhotoData,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if photoRemoved {
                                    // Show initials placeholder when photo was removed
                                    AvatarView(userId: userId, size: 100)
                                } else {
                                    AvatarView(userId: userId, size: 100)
                                }

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Text("Choose Photo")
                                        .font(AppTheme.captionFont.weight(.semibold))
                                        .foregroundColor(AppTheme.accentGreen)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppTheme.accentGreen, lineWidth: 1.5)
                                        )
                                }

                                if selectedPhotoData != nil || (!photoRemoved && (dataService.profilePhotos[userId] != nil || dataService.currentUser?.profilePhotoUrl != nil)) {
                                    Button("Remove Photo") {
                                        selectedPhotoData = nil
                                        selectedPhotoItem = nil
                                        photoRemoved = true
                                    }
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.statusSeeking)
                                }
                            }
                        }

                        // Handicap
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Handicap")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)

                            HStack(spacing: 12) {
                                Image(systemName: "number")
                                    .foregroundColor(AppTheme.accentGreen)
                                    .frame(width: 20)
                                TextField("e.g. 12.5", text: $handicapText)
                                    .font(AppTheme.bodyFont)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.inputBackground)
                                    .shadow(color: AppTheme.subtleShadow, radius: 4, x: 0, y: 2)
                            )
                        }

                        // Home Course Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Home Course")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)

                            Menu {
                                Button("None") { selectedCourse = "" }
                                ForEach(dataService.nearbyCourses) { course in
                                    Button(course.name) { selectedCourse = course.name }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(AppTheme.accentGreen)
                                        .frame(width: 20)
                                    Text(selectedCourse.isEmpty ? "Select a course" : selectedCourse)
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(selectedCourse.isEmpty ? AppTheme.mutedText : AppTheme.darkText)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.mutedText)
                                        .font(.caption)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.inputBackground)
                                        .shadow(color: AppTheme.subtleShadow, radius: 4, x: 0, y: 2)
                                )
                            }
                        }

                        // Card Theme
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Card Theme")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)

                            HStack(spacing: 14) {
                                ForEach(CardColorTheme.allCases, id: \.self) { theme in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedTheme = theme
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(theme.color)
                                                .frame(width: 40, height: 40)
                                            if selectedTheme == theme {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .scaleEffect(selectedTheme == theme ? 1.1 : 1.0)
                                    }
                                }
                                Spacer()
                            }

                            Text(selectedTheme.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTheme.color)
                        }

                        // Status Tagline
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status Tagline")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.mutedText)

                            HStack(spacing: 12) {
                                Image(systemName: "text.quote")
                                    .foregroundColor(AppTheme.accentGreen)
                                    .frame(width: 20)
                                TextField("e.g. Always down for 9 holes", text: $taglineText)
                                    .font(AppTheme.bodyFont)
                                    .onChange(of: taglineText) { _, newValue in
                                        if newValue.count > 40 {
                                            taglineText = String(newValue.prefix(40))
                                        }
                                    }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.inputBackground)
                                    .shadow(color: AppTheme.subtleShadow, radius: 4, x: 0, y: 2)
                            )

                            HStack {
                                Spacer()
                                Text("\(taglineText.count)/40")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(taglineText.count >= 40 ? AppTheme.statusSeeking : AppTheme.mutedText)
                            }
                        }

                        Button(action: saveChanges) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Save Changes")
                            }
                        }
                        .buttonStyle(GreenButtonStyle())
                        .disabled(isSaving)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                        .disabled(isSaving)
                }
            }
            .onAppear {
                if let h = dataService.currentUser?.handicap {
                    handicapText = String(format: "%.1f", h)
                }
                selectedCourse = dataService.currentUser?.homeCourse ?? ""
                selectedTheme = dataService.currentUser?.themeColor ?? .classicGreen
                taglineText = dataService.currentUser?.statusTagline ?? ""
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                        photoRemoved = false
                    }
                }
            }
        }
    }

    private func saveChanges() {
        guard let userId = dataService.currentUser?.id else { return }
        isSaving = true

        Task {
            // Upload or remove photo
            if let photoData = selectedPhotoData {
                try? await dataService.uploadProfilePhoto(for: userId, imageData: photoData)
            } else if photoRemoved {
                try? await dataService.removeProfilePhoto(for: userId)
            }

            // Update profile fields
            let handicap = Double(handicapText)
            try? await dataService.updateProfile(
                handicap: handicap,
                homeCourse: selectedCourse.isEmpty ? nil : selectedCourse,
                cardColorTheme: selectedTheme.rawValue,
                statusTagline: taglineText.trimmingCharacters(in: .whitespaces)
            )

            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}
