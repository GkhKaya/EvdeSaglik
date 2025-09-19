//
//  OpenRouterDeepseekManager.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 16.09.2025.
//

import Foundation

// MARK: - AI Service Protocols

/// Protocol for AI/ML operations
protocol AIServiceProtocol {
    func performChatRequest(messages: [DeepseekMessage]) async throws -> String
    func generateUserSummary(userData: UserModel) async throws -> String
}

/// `OpenRouterDeepseekManager` handles all interactions with the OpenRouter API for Deepseek chat completions.
/// It provides a singleton instance for making chat requests and manages API key retrieval and response parsing.
class OpenRouterDeepseekManager: AIServiceProtocol {
    /// The shared singleton instance of `OpenRouterDeepseekManager`.
    static let shared = OpenRouterDeepseekManager()

    /// Private initializer to ensure only one instance of the manager exists.
    private init() {}

    /// Performs an asynchronous chat completion request to the OpenRouter Deepseek API.
    /// - Parameter messages: The conversation history to send to the AI model.
    /// - Returns: A `String` containing the AI's response message.
    /// - Throws: `AppError.deepseekError` if any error occurs during the API request, such as missing API key, invalid URL, network issues, or malformed responses.
    func performChatRequest(messages: [DeepseekMessage]) async throws -> String {
        guard let apiKey = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"], !apiKey.isEmpty else {
            throw AppError.deepseekError(.missingAPIKey)
        }

        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw AppError.deepseekError(.invalidURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // OpenRouter recommends providing Referer and X-Title
        request.setValue("https://evdesaglik.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("EvdeSaglik", forHTTPHeaderField: "X-Title")

        // NOTE: Use unified model id; adjust if needed
        let deepseekRequest = DeepseekRequest(model: "deepseek/deepseek-chat", messages: messages)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // For readability, can be removed in production
        
        do {
            request.httpBody = try encoder.encode(deepseekRequest)
        } catch {
            throw AppError.deepseekError(.encodingFailed(error.localizedDescription))
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            throw AppError.deepseekError(.invalidResponse(statusCode: statusCode, body: responseBody))
        }

        let decoder = JSONDecoder()
        do {
            let deepseekResponse = try decoder.decode(DeepseekResponse.self, from: data)
            guard let firstChoice = deepseekResponse.choices.first else {
                throw AppError.deepseekError(.noChoicesInResponse)
            }
            return firstChoice.message.content
        } catch {
            throw AppError.deepseekError(.decodingFailed(error.localizedDescription))
        }
    }
    
    // MARK: - AIServiceProtocol Implementation
    
    /// Protocol implementation for generating user summary
    func generateUserSummary(userData: UserModel) async throws -> String {
        let messages = [
            DeepseekMessage(role: "system", content: "You are a medical assistant. Generate a concise summary of the user's health information for context in medical consultations."),
            DeepseekMessage(role: "user", content: "Generate a summary for this user: \(userData)")
        ]
        return try await performChatRequest(messages: messages)
    }
}
