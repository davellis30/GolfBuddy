import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var handicapText: String = ""
    @State private var selectedCourse: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
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
                                ForEach(dataService.courses) { course in
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
                            dataService.updateProfile(
                                handicap: handicap,
                                homeCourse: selectedCourse.isEmpty ? nil : selectedCourse
                            )
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
            }
        }
    }
}
