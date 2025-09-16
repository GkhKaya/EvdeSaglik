import Foundation

/// Represents a single message in a chat conversation for the Deepseek API.
/// It contains the role of the sender (e.g., "user", "assistant") and the content of the message.
struct DeepseekMessage: Codable {
    let role: String
    let content: String
}

/// Represents the request body sent to the OpenRouter Deepseek API for chat completions.
/// It specifies the AI model to use and the list of messages in the conversation.
struct DeepseekRequest: Codable {
    let model: String
    let messages: [DeepseekMessage]
}

/// Represents the top-level response structure received from the OpenRouter Deepseek API.
/// It includes metadata about the response, a list of generated choices, and usage statistics.
struct DeepseekResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

/// Represents a single generated choice (response) from the Deepseek AI.
/// It includes the index of the choice, the AI's message, and optional log probability information.
struct Choice: Decodable {
    let index: Int
    let message: DeepseekMessage
    let logprobs: String? // Optional: Can be null or absent in the API response.
}

/// Provides statistics about the token usage for a Deepseek API request and response.
/// It includes the number of tokens used for the prompt, the completion, and the total.
struct Usage: Decodable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}
