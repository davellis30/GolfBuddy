import SwiftUI

struct CourseListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var searchText = ""
    @State private var selectedCourse: Course?

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
                    // Search
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.mutedText)
                        TextField("Search courses", text: $searchText)
                            .font(AppTheme.bodyFont)
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

                    // Header info
                    HStack {
                        Text("Public Courses within 30 mi of Chicago")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.mutedText)
                        Spacer()
                        Text("\(filteredCourses.count) courses")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.mutedText)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredCourses) { course in
                                CourseRow(course: course)
                                    .onTapGesture { selectedCourse = course }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Courses")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedCourse) { course in
                CourseDetailSheet(course: course)
            }
        }
    }
}

struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentGreen, AppTheme.primaryGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "flag.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(course.name)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundColor(AppTheme.darkText)
                    .lineLimit(1)

                Text("\(course.city) · \(course.holes) holes · Par \(course.par)")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(course.formattedDistance)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.accentGreen)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.mutedText)
            }
        }
        .cardStyle()
    }
}

struct CourseDetailSheet: View {
    let course: Course
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header banner
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.accentGreen, AppTheme.primaryGreen],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 140)

                            VStack(spacing: 8) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                Text(course.name)
                                    .font(AppTheme.headlineFont)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        .padding(.horizontal, 20)

                        // Details
                        VStack(spacing: 14) {
                            DetailRow(icon: "mappin.circle.fill", label: "Address", value: course.fullAddress)
                            Divider()
                            DetailRow(icon: "phone.fill", label: "Phone", value: course.phone)
                            Divider()
                            DetailRow(icon: "number", label: "Holes", value: "\(course.holes)")
                            Divider()
                            DetailRow(icon: "flag.fill", label: "Par", value: "\(course.par)")
                            Divider()
                            DetailRow(icon: "location.fill", label: "Distance", value: course.formattedDistance + " from Chicago")
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 20)
                    }
                    .padding(.top, 16)
                }
            }
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

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentGreen)
                .frame(width: 24)
            Text(label)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.mutedText)
            Spacer()
            Text(value)
                .font(AppTheme.bodyFont.weight(.medium))
                .foregroundColor(AppTheme.darkText)
                .multilineTextAlignment(.trailing)
        }
    }
}
