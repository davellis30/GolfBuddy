import SwiftUI

struct CreateInviteView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCourse: String = ""
    @State private var selectedTimeSlot: DayTimeSlot?
    @State private var groupSize: Int = 4

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Weekend label
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppTheme.accentGreen)
                            Text(WeekendStatus.weekendLabel())
                                .font(AppTheme.bodyFont.weight(.medium))
                                .foregroundColor(AppTheme.darkText)
                        }
                        .padding(.top, 8)

                        // Course section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("COURSE")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.mutedText)
                                .tracking(1)

                            Menu {
                                ForEach(dataService.nearbyCourses) { course in
                                    Button("\(course.name) (\(course.formattedDistance))") {
                                        selectedCourse = course.name
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(AppTheme.accentGreen)
                                    Text(selectedCourse.isEmpty ? "Select a course" : selectedCourse)
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(selectedCourse.isEmpty ? AppTheme.mutedText : AppTheme.darkText)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.mutedText)
                                        .font(.caption)
                                }
                                .cardStyle()
                            }
                        }

                        // When section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHEN")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.mutedText)
                                .tracking(1)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(DayTimeSlot.allSlots, id: \.self) { slot in
                                    Button {
                                        selectedTimeSlot = selectedTimeSlot == slot ? nil : slot
                                    } label: {
                                        Text(slot.label)
                                            .font(AppTheme.bodyFont.weight(.medium))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(selectedTimeSlot == slot ? AppTheme.accentGreen : AppTheme.cardBackground)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedTimeSlot == slot ? Color.clear : AppTheme.mutedText.opacity(0.3), lineWidth: 1)
                                            )
                                            .foregroundColor(selectedTimeSlot == slot ? .white : AppTheme.darkText)
                                    }
                                }
                            }
                        }

                        // Group size section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GROUP SIZE")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.mutedText)
                                .tracking(1)

                            HStack(spacing: 12) {
                                ForEach([2, 3, 4], id: \.self) { size in
                                    Button {
                                        groupSize = size
                                    } label: {
                                        Text("\(size) players")
                                            .font(AppTheme.bodyFont.weight(.medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(groupSize == size ? AppTheme.accentGreen : AppTheme.cardBackground)
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(groupSize == size ? Color.clear : AppTheme.mutedText.opacity(0.3), lineWidth: 1)
                                            )
                                            .foregroundColor(groupSize == size ? .white : AppTheme.darkText)
                                    }
                                }
                                Spacer()
                            }
                        }

                        // Create button
                        Button("Create Invite") {
                            guard let timeSlot = selectedTimeSlot else { return }
                            dataService.createOpenInvite(
                                courseName: selectedCourse,
                                timeSlot: timeSlot,
                                groupSize: groupSize
                            )
                            dismiss()
                        }
                        .buttonStyle(GreenButtonStyle())
                        .disabled(selectedCourse.isEmpty || selectedTimeSlot == nil)
                        .opacity(selectedCourse.isEmpty || selectedTimeSlot == nil ? 0.5 : 1.0)

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Create Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
        }
    }
}
