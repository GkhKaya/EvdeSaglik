import SwiftUI

struct ChatbotView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ChatbotViewModel
    @State private var hasAppeared: Bool = false
    @FocusState private var isInputFocused: Bool
    let initialMessage: String

    init(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager, userManager: UserManager, initialMessage: String = "") {
        _viewModel = StateObject(wrappedValue: ChatbotViewModel(authManager: authManager, firestoreManager: firestoreManager, userManager: userManager))
        self.initialMessage = initialMessage
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            HStack {
                Text(NSLocalizedString("Chatbot.Title", comment: "Health Chatbot"))
                    .font(.headlineResponsive)
                    .bold()
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2Responsive)
                        .foregroundStyle(.gray)
                }
            }
            .padding(ResponsivePadding.medium)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)

            // Chat messages area
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ResponsivePadding.small) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id) // Assign ID for programmatic scrolling
                        }
                    }
                    .padding(ResponsivePadding.medium)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    // Scroll to the bottom when a new message is added
                    if let lastMessageId = viewModel.messages.last?.id {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if !hasAppeared {
                        // Pass the initialMessage to the ViewModel's new processing method
                        viewModel.processInitialMessage(message: self.initialMessage)
                        hasAppeared = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Reduced delay for better UX
                            isInputFocused = true
                        }
                    }
                }
            }

            // Input field and send button
            VStack(spacing: 0) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.captionResponsive)
                        .foregroundStyle(.red)
                        .padding(.horizontal, ResponsivePadding.medium)
                }

                HStack(alignment: .bottom, spacing: ResponsivePadding.small) {
                    CustomTextField(
                        title: "",
                        placeholder: NSLocalizedString("Chatbot.Placeholder", comment: "Ask a health question..."),
                        icon: "",
                        text: $viewModel.currentMessageText,
                        isMultiline: false // Single line for chatbot input
                    )
                    .focused($isInputFocused)
                    .animation(.none, value: viewModel.currentMessageText.isEmpty) // Disable animation for text field for smooth single-line experience
                    .frame(minHeight: 40)

                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.titleResponsive)
                            .foregroundStyle(.blue)
                    }
                    .disabled(viewModel.currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal, ResponsivePadding.medium)
                .padding(.vertical, ResponsivePadding.small)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1, alignment: .top)
                        .foregroundStyle(Color(.separator)),
                    alignment: .top
                )
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct ChatMessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer() // Pushes user message to the right
            }
            
            VStack(alignment: .leading, spacing: ResponsivePadding.extraSmall) {
                Text(message.content)
                    .font(.bodyResponsive)
                    .padding(ResponsivePadding.small)
                    .background(message.role == "user" ? Color.blue.opacity(0.8) : Color(.systemGray5))
                    .foregroundStyle(message.role == "user" ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: ResponsiveRadius.medium))

                if message.isThinking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                        .padding(.leading, ResponsivePadding.small)
                }
            }
            // Adjust alignment based on role for multi-line messages and thinking indicator
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.role == "user" ? .trailing : .leading)
            
            if message.role == "assistant" {
                Spacer() // Pushes assistant message to the left
            }
        }
    }
}

#Preview {
    ChatbotView(
        authManager: FirebaseAuthManager(),
        firestoreManager: FirestoreManager(),
        userManager: UserManager()
    )
}
