import Foundation

/// Manages API requests to the OpenRouter Deepseek chat completion endpoint.
class OpenRouterDeepseekManager {
    static let shared = OpenRouterDeepseekManager() // Singleton instance

    private init() {} // Private initializer to ensure singleton usage

    /// Performs a chat completion request to the OpenRouter Deepseek API.
    /// - Parameter messages: An array of DeepseekMessage objects representing the conversation history.
    /// - Returns: The AI's response as a String.
    func performChatRequest(messages: [DeepseekMessage]) async throws -> String {
        guard let apiKey = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"], !apiKey.isEmpty else {
            throw AppError.deepseekError(.missingAPIKey)
        }

        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw AppError.deepseekError(.invalidURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("deepseek-coder", forHTTPHeaderField: "HTTP-Referer") // Required by OpenRouter for some models

        // Create the request body
        let requestBody = DeepseekRequest(model: "deepseek-chat", messages: messages)

        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            let (data, response) = try await URLSession.shared.upload(for: request, from: jsonData)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.deepseekError(.invalidResponse)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorData = String(data: data, encoding: .utf8) ?? "No error data"
                print("Deepseek API Error (Status Code: \(httpResponse.statusCode)): \(errorData)")
                throw AppError.deepseekError(.apiError(statusCode: httpResponse.statusCode, message: errorData))
            }

            let deepseekResponse = try JSONDecoder().decode(DeepseekResponse.self, from: data)

            guard let firstChoice = deepseekResponse.choices.first else {
                throw AppError.deepseekError(.noChoicesInResponse)
            }

            return firstChoice.message.content
        } catch let decodingError as DecodingError {
            print("Deepseek Decoding Error: \(decodingError)")
            throw AppError.deepseekError(.decodingError(decodingError.localizedDescription))
        } catch {
            print("Deepseek Network Error: \(error)")
            throw AppError.deepseekError(.networkError(error.localizedDescription))
        }
    }
}
