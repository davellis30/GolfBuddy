import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var dataService: DataService
    let friend: User
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(dataService.activeConversationMessages) { message in
                            MessageBubble(
                                message: message,
                                isSent: message.senderId == dataService.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onAppear {
                    dataService.openConversation(with: friend.id)
                    scrollToBottom(proxy: proxy)
                }
                .onDisappear {
                    dataService.closeConversation()
                }
                .onChange(of: dataService.activeConversationMessages.count) {
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Message...", text: $messageText)
                    .font(AppTheme.bodyFont)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cream)
                    )

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.mutedText : AppTheme.accentGreen)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.cardBackground)
        }
        .background(AppTheme.cream.ignoresSafeArea())
        .navigationTitle(friend.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dataService.sendMessage(to: friend.id, text: trimmed)
        messageText = ""
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let last = dataService.activeConversationMessages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isSent: Bool

    var body: some View {
        HStack {
            if isSent { Spacer(minLength: 60) }

            VStack(alignment: isSent ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(isSent ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isSent ? AppTheme.accentGreen : AppTheme.receivedBubble)
                    )

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(AppTheme.mutedText)
            }

            if !isSent { Spacer(minLength: 60) }
        }
    }
}
