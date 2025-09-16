//
//  OpenRouterDeepseekManager.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 16.09.2025.
//

import Foundation
import EvdeSaglik // Import the main module to access DeepseekModels

/// `OpenRouterDeepseekManager` handles all interactions with the OpenRouter API for Deepseek chat completions.
/// It provides a singleton instance for making chat requests and manages API key retrieval and response parsing.
class OpenRouterDeepseekManager {
    /// The shared singleton instance of `OpenRouterDeepseekManager`.
    static let shared = OpenRouterDeepseekManager()

    /// Private initializer to ensure only one instance of the manager exists.
    private init() {}

    /// Performs an asynchronous chat completion request to the OpenRouter Deepseek API.
    ///
    /// - Parameter message: The user's message to send to the AI model.
    /// - Returns: A `String` containing the AI's response message.
    /// - Throws: `AppError.deepseekError` if any error occurs during the API request, such as missing API key, invalid URL, network issues, or malformed responses.
    func performChatRequest(message: String) async throws -> String {
        guard let apiKey = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] else {
            throw AppError.deepseekError(.missingAPIKey)
        }

        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw AppError.deepseekError(.invalidURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages = [DeepseekMessage(role: "user", content: message)]
        let deepseekRequest = DeepseekRequest(model: "deepseek/deepseek-chat-v3.1:free", messages: messages)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // For readability, can be removed in production
        
        do {
            request.httpBody = try encoder.encode(deepseekRequest)
        } catch {
            throw AppError.deepseekError(.encodingFailed(error.localizedDescription))
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
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
}
