import SwiftUI

struct CoursePickerView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCourse: String
    @State private var searchText = ""

    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return dataService.courses
        }
        let lowered = searchText.lowercased()
        return dataService.courses.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.city.lowercased().contains(lowered)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.mutedText)
                        TextField("Search by name or city", text: $searchText)
                            .font(AppTheme.bodyFont)
                            .textInputAutocapitalization(.never)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.mutedText)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    HStack {
                        Text("\(filteredCourses.count) courses")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.mutedText)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // "None" option
                            Button(action: {
                                selectedCourse = ""
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(AppTheme.mutedText)
                                        .frame(width: 24)
                                    Text("None")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.mutedText)
                                    Spacer()
                                    if selectedCourse.isEmpty {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppTheme.accentGreen)
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedCourse.isEmpty ? AppTheme.accentGreen.opacity(0.08) : Color.white)
                                        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                )
                            }

                            ForEach(filteredCourses) { course in
                                let isSelected = selectedCourse == course.name
                                Button(action: {
                                    selectedCourse = course.name
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "flag.fill")
                                            .foregroundColor(isSelected ? AppTheme.accentGreen : AppTheme.mutedText)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(course.name)
                                                .font(AppTheme.bodyFont.weight(isSelected ? .semibold : .regular))
                                                .foregroundColor(AppTheme.darkText)
                                                .lineLimit(1)
                                            Text("\(course.city) · \(course.holes)h · Par \(course.par) · \(course.formattedDistance)")
                                                .font(AppTheme.captionFont)
                                                .foregroundColor(AppTheme.mutedText)
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.accentGreen)
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? AppTheme.accentGreen.opacity(0.08) : Color.white)
                                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
        }
    }
}
