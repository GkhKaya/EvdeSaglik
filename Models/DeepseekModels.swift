import Foundation

/// Represents a single message in the Deepseek API conversation.
struct DeepseekMessage: Codable {
    let role: String // "system", "user", or "assistant"
    let content: String
}

/// Request body for the Deepseek API chat completion endpoint.
struct DeepseekRequest: Codable {
    let model: String
    let messages: [DeepseekMessage]
}

/// Response from the Deepseek API chat completion endpoint.
struct DeepseekResponse: Codable {
    let choices: [Choice]
    let usage: Usage?
}

/// A choice in the Deepseek API response.
struct Choice: Codable {
    let message: DeepseekMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

/// Usage statistics from the Deepseek API response.
struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
