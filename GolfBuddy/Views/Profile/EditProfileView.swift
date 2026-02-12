import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var handicapText: String = ""
    @State private var selectedCourse: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

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

                                if selectedPhotoData != nil || dataService.profilePhotos[userId] != nil {
                                    Button("Remove Photo") {
                                        selectedPhotoData = nil
                                        selectedPhotoItem = nil
                                        dataService.setProfilePhoto(for: userId, imageData: nil)
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
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
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
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                )
                            }
                        }

                        Button("Save Changes") {
                            let handicap = Double(handicapText)
                            if let userId = dataService.currentUser?.id, let photoData = selectedPhotoData {
                                dataService.setProfilePhoto(for: userId, imageData: photoData)
                            }
                            Task {
                                try? await dataService.updateProfile(
                                    handicap: handicap,
                                    homeCourse: selectedCourse.isEmpty ? nil : selectedCourse
                                )
                            }
                            dismiss()
                        }
                        .buttonStyle(GreenButtonStyle())
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
                }
            }
            .onAppear {
                if let h = dataService.currentUser?.handicap {
                    handicapText = String(format: "%.1f", h)
                }
                selectedCourse = dataService.currentUser?.homeCourse ?? ""
                if let userId = dataService.currentUser?.id {
                    selectedPhotoData = dataService.profilePhotos[userId]
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
            }
        }
    }
}
