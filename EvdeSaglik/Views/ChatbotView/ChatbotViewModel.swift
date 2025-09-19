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
class ChatbotViewModel: BaseViewModel {
    @Published var messages: [ChatMessage] = []
    @Published var currentMessageText: String = ""
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
        sendMessageToAI(message, isInitial: true)
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

    /// Common method to send messages to AI, eliminating code duplication between initial and regular messages.
    /// - Parameters:
    ///   - message: The message content to send
    ///   - isInitial: Whether this is an initial message (affects logging only)
    private func sendMessageToAI(_ message: String, isInitial: Bool) {
        let methodName = isInitial ? "_sendInitialMessage" : "sendMessage"
        print("\n--- \(methodName) called with message: \(message)")
        
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("\(methodName): message is empty or whitespace.")
            return 
        }
        
        // Add user message to chat history
        let userMessage = addMessage(role: "user", content: message)
        print("\(methodName): user message added.")

        // Add thinking message for the assistant
        let thinkingMessage = addMessage(role: "assistant", content: "", isThinking: true)
        thinkingMessageID = thinkingMessage.id
        print("\(methodName): thinking message added with ID \(thinkingMessageID?.uuidString ?? "nil").")

        performAsyncOperation(
            operation: {
                let messagesForAPI = await self.prepareMessagesForAPI()
                let aiResponse = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messagesForAPI)
                return aiResponse
            },
            context: "ChatbotViewModel.\(methodName)",
            onSuccess: { [weak self] aiResponse in
                self?.handleAIResponse(aiResponse, methodName: methodName)
            }
        )
    }
    
    /// Prepares messages for API request including user context and conversation history.
    private func prepareMessagesForAPI() async -> [DeepseekMessage] {
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
        
        return messagesForAPI
    }
    
    /// Handles successful AI response by updating the thinking message.
    private func handleAIResponse(_ aiResponse: String, methodName: String) {
        DispatchQueue.main.async {
            if let id = self.thinkingMessageID {
                print("\(methodName): Updating thinking message \(id.uuidString) with AI response.")
                self.updateMessage(id: id, newContent: aiResponse, isThinking: false)
            } else {
                // Fallback if thinkingMessageID was not set (should not happen)
                print("\(methodName): thinkingMessageID nil, adding new assistant message with AI response.")
                self.addMessage(role: "assistant", content: aiResponse)
            }
            self.thinkingMessageID = nil
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
        currentMessageText = "" // Clear the input field
        sendMessageToAI(userMessageContent, isInitial: false)
    }
}

