//
//  ChatVotView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 16.09.2025.
//

import SwiftUI

struct ChatbotView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ChatbotViewModel
    @State private var hasAppeared: Bool = false // To ensure onAppear logic runs only once
    
    @FocusState private var isInputFocused: Bool // 👈 Klavye odak için
    let initialMessage: String // Store initialMessage as a property
    
    init(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager, userManager: UserManager, initialMessage: String = "") {
        _viewModel = StateObject(wrappedValue: ChatbotViewModel(authManager: authManager, firestoreManager: firestoreManager, userManager: userManager))
        self.initialMessage = initialMessage // Assign to the new property
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages display area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            ForEach(viewModel.messages) { message in
                                ChatMessageView(message: message)
                            }
                        }
                        .padding(ResponsivePadding.medium)
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Input field and send button
                HStack {
                    CustomTextField(
                        title: "",
                        placeholder: NSLocalizedString("Chatbot.Input.Placeholder", comment: "Type a message..."),
                        icon: "", // No icon for chatbot input
                        text: $viewModel.currentMessageText,
                        isSecure: false,
                        isMultiline: false // Allow multiline input
                    )
                    .focused($isInputFocused) // 👈 Odak buraya veriliyor

                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title1Responsive)
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(viewModel.currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal, ResponsivePadding.medium)
                .padding(.vertical, ResponsivePadding.small)
                .background(Color(.systemBackground))
                .shadow(color: Color(.systemGray).opacity(0.1), radius: 5, x: 0, y: -5)
            }
            .navigationTitle(NSLocalizedString("Chatbot.Title", comment: "Chat with AI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.gray)
                    }
                }
            }
            .onAppear {
                if !hasAppeared {
                    // Pass the initialMessage to the ViewModel's new processing method
                    viewModel.processInitialMessage(message: self.initialMessage)
                    hasAppeared = true
                }
                // 👇 Görünce klavye aç
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInputFocused = true
                }
            }
        }
        .messageDisplay(for: viewModel)
    }
}

/// A view to display individual chat messages.
struct ChatMessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
                Text(message.content)
                    .padding(ResponsivePadding.small)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                if message.isThinking {
                    ProgressView()
                        .padding(ResponsivePadding.small)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(message.content)
                        .padding(ResponsivePadding.small)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
            }
        }
    }
}
