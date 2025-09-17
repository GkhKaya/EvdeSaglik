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

    /// Processes the initial message provided when the chatbot view is presented.
    /// If an initial message is set, it sends it; otherwise, it adds a default greeting.
    func processInitialMessage(message: String) {
        print("\n--- processInitialMessage called. message: \(message), messages count: \(messages.count)")
        if !message.isEmpty {
            // Send the initial message directly as a user message
            self._sendInitialMessage(message: message)
        } else if self.messages.isEmpty { // Only add greeting if messages are truly empty
            // Add a default greeting if no initial message is provided
            print("Adding default greeting.")
            self.addMessage(role: "assistant", content: NSLocalizedString("Chatbot.Greeting", comment: "Hello! How can I help you today?"))
        }
    }

    /// Handles the initial message logic when the view appears.
    /// If an initial message is set, it sends it; otherwise, it adds a default greeting.
    func handleInitialMessage() {
        print("\n--- handleInitialMessage called. initialMessage: \(initialMessage), messages count: \(messages.count)")
        // The logic for handling initial message is moved to processInitialMessage.
        // This method will now ensure the initialMessage property is cleared and calls the processing method.
        let messageToSend = self.initialMessage
        self.initialMessage = "" // Clear after processing
        self.processInitialMessage(message: messageToSend)
    }

    /// Sends an initial message directly to the Deepseek API as a user message.
    private func _sendInitialMessage(message: String) {
        print("\n--- _sendInitialMessage called with message: \(message)")
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("_sendInitialMessage: message is empty or whitespace.")
            return 
        }
        
        let userMessageContent = message
        let newMessage = self.addMessage(role: "user", content: userMessageContent)
        isLoading = true
        errorMessage = nil
        print("_sendInitialMessage: user message added, isLoading = true.")

        // Add a thinking message for the assistant
        let thinkingMessage = self.addMessage(role: "assistant", content: "", isThinking: true)
        self.thinkingMessageID = thinkingMessage.id // Store the ID of the thinking message
        print("_sendInitialMessage: thinking message added with ID \(self.thinkingMessageID?.uuidString ?? "nil").")

        Task {
            defer { // Ensure isLoading and thinkingMessageID are reset regardless of success or failure
                DispatchQueue.main.async {
                    print("_sendInitialMessage defer block: Setting isLoading = false, thinkingMessageID = nil.")
                    self.isLoading = false
                    self.thinkingMessageID = nil
                }
            }

            do {
                // Prepare messages for API with user context
                let userSummary = await userManager.generateUserSummaryPrompt()
                var messagesForAPI: [DeepseekMessage] = []
                
                // Add user summary as system message if available
                if !userSummary.isEmpty {
                    messagesForAPI.append(DeepseekMessage(role: "system", content: userSummary))
                }
                
                // Add conversation history (excluding thinking messages)
                let conversationMessages = self.messages.filter { !$0.isThinking }
                for message in conversationMessages {
                    messagesForAPI.append(DeepseekMessage(role: message.role, content: message.content))
                }
                
                let aiResponse = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messagesForAPI)
                
                // Update the thinking message with the actual AI response
                if let id = self.thinkingMessageID {
                    print("_sendInitialMessage: Updating thinking message \(id.uuidString) with AI response.")
                    self.updateMessage(id: id, newContent: aiResponse, isThinking: false)
                } else {
                    // Fallback if thinkingMessageID was not set (should not happen)
                    print("_sendInitialMessage: thinkingMessageID nil, adding new assistant message with AI response.")
                    self.addMessage(role: "assistant", content: aiResponse)
                }
            } catch let appError as AppError {
                DispatchQueue.main.async {
                    print("_sendInitialMessage catch AppError: \(appError.localizedDescription).")
                    self.errorMessage = appError.localizedDescription
                    if let id = self.thinkingMessageID {
                        self.updateMessage(id: id, newContent: "Error: \(appError.localizedDescription)", isThinking: false)
                    } else {
                        self.addMessage(role: "assistant", content: "Error: \(appError.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("_sendInitialMessage catch generic error: \(error.localizedDescription).")
                    self.errorMessage = error.localizedDescription
                    if let id = self.thinkingMessageID {
                        self.updateMessage(id: id, newContent: "Error: \(error.localizedDescription)", isThinking: false)
                    }
                     else {
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
    private func addMessage(role: String, content: String, isThinking: Bool = false) -> ChatMessage {
        let newMessage = ChatMessage(role: role, content: content, isThinking: isThinking)
        DispatchQueue.main.async {
            self.messages.append(newMessage)
            print("addMessage: Added \(role) message with content: '\(content)', isThinking: \(isThinking), ID: \(newMessage.id.uuidString). Current messages count: \(self.messages.count).")
        }
        return newMessage
    }
    
    /// Updates an existing message in the chat history.
    private func updateMessage(id: UUID, newContent: String, isThinking: Bool = false) {
        DispatchQueue.main.async {
            if let index = self.messages.firstIndex(where: { $0.id == id }) {
                self.messages[index].content = newContent
                self.messages[index].isThinking = isThinking
                print("updateMessage: Updated message \(id.uuidString) to content: '\(newContent)', isThinking: \(isThinking).")
            } else {
                print("updateMessage: Failed to find message with ID \(id.uuidString) for update.")
            }
        }
    }

    /// Sends the current message in `currentMessageText` to the Deepseek API.
    func sendMessage() {
        print("\n--- sendMessage called. currentMessageText: \(currentMessageText)")
        guard !currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("sendMessage: currentMessageText is empty or whitespace.")
            return 
        }
        
        let userMessageContent = currentMessageText
        let newMessage = self.addMessage(role: "user", content: userMessageContent)
        currentMessageText = ""
        isLoading = true
        errorMessage = nil
        print("sendMessage: user message added, isLoading = true.")

        // Add a thinking message for the assistant
        let thinkingMessage = self.addMessage(role: "assistant", content: "", isThinking: true)
        self.thinkingMessageID = thinkingMessage.id // Store the ID of the thinking message
        print("sendMessage: thinking message added with ID \(self.thinkingMessageID?.uuidString ?? "nil").")

        Task {
            defer { // Ensure isLoading and thinkingMessageID are reset regardless of success or failure
                DispatchQueue.main.async {
                    print("sendMessage defer block: Setting isLoading = false, thinkingMessageID = nil.")
                    self.isLoading = false
                    self.thinkingMessageID = nil
                }
            }
            
            do {
                // Prepare messages for API with user context
                let userSummary = await userManager.generateUserSummaryPrompt()
                var messagesForAPI: [DeepseekMessage] = []
                
                // Add user summary as system message if available
                if !userSummary.isEmpty {
                    messagesForAPI.append(DeepseekMessage(role: "system", content: userSummary))
                }
                
                // Add conversation history (excluding thinking messages)
                let conversationMessages = self.messages.filter { !$0.isThinking }
                for message in conversationMessages {
                    messagesForAPI.append(DeepseekMessage(role: message.role, content: message.content))
                }
                
                let aiResponse = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messagesForAPI)
                
                // Update the thinking message with the actual AI response
                if let id = self.thinkingMessageID {
                    print("sendMessage: Updating thinking message \(id.uuidString) with AI response.")
                    self.updateMessage(id: id, newContent: aiResponse, isThinking: false)
                } else {
                    // Fallback if thinkingMessageID was not set (should not happen)
                    print("sendMessage: thinkingMessageID nil, adding new assistant message with AI response.")
                    self.addMessage(role: "assistant", content: aiResponse)
                }
            } catch let appError as AppError {
                DispatchQueue.main.async {
                    print("sendMessage catch AppError: \(appError.localizedDescription).")
                    self.errorMessage = appError.localizedDescription
                    if let id = self.thinkingMessageID {
                        self.updateMessage(id: id, newContent: "Error: \(appError.localizedDescription)", isThinking: false)
                    } else {
                        self.addMessage(role: "assistant", content: "Error: \(appError.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("sendMessage catch generic error: \(error.localizedDescription).")
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
