import Foundation
import SwiftUI
import Combine

/// Represents a single message within the chatbot UI.
/// Conforms to `Identifiable` for use in SwiftUI's `ForEach`.
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    var content: String
    var isThinking: Bool = false // New property to indicate if the AI is thinking
}

/// ViewModel for the `ChatbotView`, managing chat logic, API interactions, and UI state.
class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentMessageText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var initialMessage: String = "" // New published property for initial message

    private let authManager: FirebaseAuthManager
    private let firestoreManager: FirestoreManager
    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()
    private var thinkingMessageID: UUID? // To track the AI's thinking message

    init(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager, userManager: UserManager) {
        self.authManager = authManager
        self.firestoreManager = firestoreManager
        self.userManager = userManager
    }

    /// Handles the initial message logic when the view appears.
    /// If an initial message is set, it sends it; otherwise, it adds a default greeting.
    func handleInitialMessage() {
        if !initialMessage.isEmpty {
            // Use currentMessageText to prepare for sending
            let messageToSend = initialMessage
            initialMessage = "" // Clear after processing
            
            self._sendInitialMessage(message: messageToSend)
        } else if self.messages.isEmpty { // Only add greeting if messages are truly empty
            // Add a default greeting if no initial message is provided
            self.addMessage(role: "assistant", content: NSLocalizedString("Chatbot.Greeting", comment: "Hello! How can I help you today?"))
        }
    }

    /// Sends an initial message directly to the Deepseek API as a user message.
    private func _sendInitialMessage(message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessageContent = message
        self.addMessage(role: "user", content: userMessageContent)
        isLoading = true
        errorMessage = nil

        // Add a thinking message for the assistant
        self.addMessage(role: "assistant", content: "", isThinking: true)
        self.thinkingMessageID = self.messages.last?.id // Store the ID of the thinking message

        Task {
            defer { // Ensure isLoading and thinkingMessageID are reset regardless of success or failure
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.thinkingMessageID = nil
                }
            }

            do {
                // Optionally, include user context from UserManager
                let userSummary = await userManager.generateUserSummaryPrompt()
                let fullMessage = userSummary.isEmpty ? userMessageContent : "\(userSummary)\n\n\(userMessageContent)"
                
                let aiResponse = try await OpenRouterDeepseekManager.shared.performChatRequest(message: fullMessage)
                
                // Update the thinking message with the actual AI response
                if let id = self.thinkingMessageID {
                    self.updateMessage(id: id, newContent: aiResponse, isThinking: false)
                } else {
                    // Fallback if thinkingMessageID was not set (should not happen)
                    self.addMessage(role: "assistant", content: aiResponse)
                }
            } catch let appError as AppError {
                DispatchQueue.main.async {
                    self.errorMessage = appError.localizedDescription
                    if let id = self.thinkingMessageID {
                        self.updateMessage(id: id, newContent: "Error: \(appError.localizedDescription)", isThinking: false)
                    } else {
                        self.addMessage(role: "assistant", content: "Error: \(appError.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    if let id = self.thinkingMessageID {
                        self.updateMessage(id: id, newContent: "Error: \(error.localizedDescription)", isThinking: false)
                    } else {
                        self.addMessage(role: "assistant", content: "Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Adds a new message to the chat history.
    /// - Parameters:
    ///   - role: The role of the sender ("user" or "assistant").
    ///   - content: The text content of the message.
    private func addMessage(role: String, content: String, isThinking: Bool = false) {
        DispatchQueue.main.async {
            self.messages.append(ChatMessage(role: role, content: content, isThinking: isThinking))
        }
    }
    
    /// Updates an existing message in the chat history.
    private func updateMessage(id: UUID, newContent: String, isThinking: Bool = false) {
        DispatchQueue.main.async {
            if let index = self.messages.firstIndex(where: { $0.id == id }) {
                self.messages[index].content = newContent
                self.messages[index].isThinking = isThinking
            }
        }
    }

    /// Sends the current message in `currentMessageText` to the Deepseek API.
    func sendMessage() {
        guard !currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessageContent = currentMessageText
        self.addMessage(role: "user", content: userMessageContent)
        currentMessageText = ""
        isLoading = true
        errorMessage = nil

        // Add a thinking message for the assistant
        self.addMessage(role: "assistant", content: "", isThinking: true)
        self.thinkingMessageID = self.messages.last?.id // Store the ID of the thinking message

        Task {
            defer { // Ensure isLoading and thinkingMessageID are reset regardless of success or failure
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.thinkingMessageID = nil
                }
            }
            
            do {
                // Optionally, include user context from UserManager
                let userSummary = await userManager.generateUserSummaryPrompt()
                let fullMessage = userSummary.isEmpty ? userMessageContent : "\(userSummary)\n\n\(userMessageContent)"
                
                let aiResponse = try await OpenRouterDeepseekManager.shared.performChatRequest(message: fullMessage)
                
                // Update the thinking message with the actual AI response
                if let id = self.thinkingMessageID {
                    self.updateMessage(id: id, newContent: aiResponse, isThinking: false)
                } else {
                    // Fallback if thinkingMessageID was not set (should not happen)
                    self.addMessage(role: "assistant", content: aiResponse)
                }
            } catch let appError as AppError {
                DispatchQueue.main.async {
                    self.errorMessage = appError.localizedDescription
                    if let id = self.thinkingMessageID {
                        self.updateMessage(id: id, newContent: "Error: \(appError.localizedDescription)", isThinking: false)
                    } else {
                        self.addMessage(role: "assistant", content: "Error: \(appError.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    if let id = self.thinkingMessageID {
                        self.updateMessage(id: id, newContent: "Error: \(error.localizedDescription)", isThinking: false)
                    } else {
                        self.addMessage(role: "assistant", content: "Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
