import SwiftUI

struct TeeTimeResultsView: View {
    @ObservedObject var searchService: TeeTimeSearchService
    @Environment(\.dismiss) private var dismiss

    private var totalTeeTimes: Int {
        searchService.results.reduce(0) { $0 + $1.teeTimes.count }
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            switch searchService.searchState {
            case .searching:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(AppTheme.accentGreen)
                    Text("Searching \(searchService.results.isEmpty ? "courses" : "\(searchService.results.count) courses")...")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.mutedText)
                }

            case .results:
                if totalTeeTimes == 0 {
                    emptyState
                } else {
                    resultsList
                }

            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.gold)
                    Text(message)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.mutedText)
                        .multilineTextAlignment(.center)
                    Button("Go Back") { dismiss() }
                        .buttonStyle(OutlineButtonStyle())
                }
                .padding(40)

            case .idle:
                EmptyView()
            }
        }
        .navigationTitle("Tee Times")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.mutedText.opacity(0.5))
            Text("No Tee Times Found")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.darkText)
            Text("Try different times or add more courses to your search.")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.mutedText)
                .multilineTextAlignment(.center)
            Button("Refine Search") { dismiss() }
                .buttonStyle(GreenButtonStyle())
                .padding(.top, 8)
        }
        .padding(40)
    }

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 4) {
                // Summary
                HStack {
                    Text("\(totalTeeTimes) tee times found")
                        .font(AppTheme.captionFont.weight(.medium))
                        .foregroundColor(AppTheme.accentGreen)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                LazyVStack(spacing: 20) {
                    ForEach(searchService.results) { result in
                        courseSection(result)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    private func courseSection(_ result: TeeTimeSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Course header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.course.name)
                        .font(AppTheme.bodyFont.weight(.bold))
                        .foregroundColor(AppTheme.darkText)
                    Text(result.course.city)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                }
                Spacer()
                if result.isEmpty {
                    Text("No times")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                } else {
                    Text("\(result.teeTimes.count) available")
                        .font(AppTheme.captionFont.weight(.medium))
                        .foregroundColor(AppTheme.accentGreen)
                }
            }

            if result.isEmpty {
                HStack {
                    Spacer()
                    Text("No available tee times for this course")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.mutedText)
                    Spacer()
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                )
            } else {
                ForEach(result.teeTimes) { teeTime in
                    TeeTimeCard(teeTime: teeTime)
                }
            }
        }
    }
}
