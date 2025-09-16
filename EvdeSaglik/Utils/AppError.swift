//
//  AppError.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation

enum AppError: LocalizedError {
    case authError(AuthError)
    case firestoreError(FirestoreError)
    case deepseekError(DeepseekError) // New case for Deepseek API errors
    // case aiBackendError(AIBackendError) // Uncomment if AI/Backend errors are needed

    var errorDescription: String? {
        switch self {
        case .authError(let error):
            return error.errorDescription
        case .firestoreError(let error):
            return error.errorDescription
        case .deepseekError(let error):
            return error.errorDescription
        // case .aiBackendError(let error):
        //     return error.errorDescription
        }
    }
}

enum AuthError: LocalizedError {
    case registrationFailed(String)
    case loginFailed(String)
    case passwordResetFailed(String)
    case emailUpdateFailed(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let message):
            return NSLocalizedString("Auth.Error.RegistrationFailed", comment: message)
        case .loginFailed(let message):
            return NSLocalizedString("Auth.Error.LoginFailed", comment: message)
        case .passwordResetFailed(let message):
            return NSLocalizedString("Auth.Error.PasswordResetFailed", comment: message)
        case .emailUpdateFailed(let message):
            return NSLocalizedString("Auth.Error.EmailUpdateFailed", comment: message)
        case .unknown:
            return NSLocalizedString("Auth.Error.Unknown", comment: "Bilinmeyen bir kimlik doğrulama hatası oluştu.")
        }
    }
}

enum FirestoreError: LocalizedError {
    case readFailed(String)
    case writeFailed(String)
    case documentNotFound(String)
    case networkError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .readFailed(let message):
            return NSLocalizedString("Firestore.Error.ReadFailed", comment: message)
        case .writeFailed(let message):
            return NSLocalizedString("Firestore.Error.WriteFailed", comment: message)
        case .documentNotFound(let message):
            return NSLocalizedString("Firestore.Error.DocumentNotFound", comment: message)
        case .networkError(let message):
            return NSLocalizedString("Firestore.Error.NetworkError", comment: message)
        case .unknown:
            return NSLocalizedString("Firestore.Error.Unknown", comment: "Bilinmeyen bir Firestore hatası oluştu.")
        }
    }
}

/// Represents errors that can occur during interactions with the OpenRouter Deepseek API.
/// These errors provide specific context for API-related issues, helping with debugging and user feedback.
enum DeepseekError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case encodingFailed(String)
    case invalidResponse(statusCode: Int, body: String)
    case decodingFailed(String)
    case noChoicesInResponse
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return NSLocalizedString("Deepseek.Error.MissingAPIKey", comment: "Deepseek API Key not found in environment variables.")
        case .invalidURL:
            return NSLocalizedString("Deepseek.Error.InvalidURL", comment: "Invalid URL for OpenRouter API.")
        case .encodingFailed(let message):
            return NSLocalizedString("Deepseek.Error.EncodingFailed", comment: "Failed to encode request data: \(message)")
        case .invalidResponse(let statusCode, let body):
            return NSLocalizedString("Deepseek.Error.InvalidResponse", comment: "Invalid response from OpenRouter API. Status Code: \(statusCode), Body: \(body)")
        case .decodingFailed(let message):
            return NSLocalizedString("Deepseek.Error.DecodingFailed", comment: "Failed to decode API response: \(message)")
        case .noChoicesInResponse:
            return NSLocalizedString("Deepseek.Error.NoChoices", comment: "No choices found in the Deepseek API response.")
        case .custom(let message):
            return NSLocalizedString("Deepseek.Error.Custom", comment: message)
        }
    }
}

