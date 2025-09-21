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
    case deepseekError(DeepseekError)
    case validationError(ValidationError)
    case networkError(NetworkError)
    case businessLogicError(BusinessLogicError)
    // case aiBackendError(AIBackendError) // Uncomment if AI/Backend errors are needed

    var errorDescription: String? {
        switch self {
        case .authError(let error):
            return error.errorDescription
        case .firestoreError(let error):
            return error.errorDescription
        case .deepseekError(let error):
            return error.errorDescription
        case .validationError(let error):
            return error.errorDescription
        case .networkError(let error):
            return error.errorDescription
        case .businessLogicError(let error):
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

/// Validation errors for form inputs and data validation
enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidFormat(String)
    case passwordTooWeak
    case emailInvalid
    case ageInvalid
    case nameTooShort
    case requiredFieldMissing(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return NSLocalizedString("Validation.Error.EmptyField", comment: "\(field) field cannot be empty")
        case .invalidFormat(let field):
            return NSLocalizedString("Validation.Error.InvalidFormat", comment: "Invalid \(field) format")
        case .passwordTooWeak:
            return NSLocalizedString("Validation.Error.WeakPassword", comment: "Password must be at least 6 characters")
        case .emailInvalid:
            return NSLocalizedString("Validation.Error.InvalidEmail", comment: "Please enter a valid email address")
        case .ageInvalid:
            return NSLocalizedString("Validation.Error.InvalidAge", comment: "Please enter a valid age")
        case .nameTooShort:
            return NSLocalizedString("Validation.Error.NameTooShort", comment: "Name must be at least 2 characters")
        case .requiredFieldMissing(let field):
            return NSLocalizedString("Validation.Error.RequiredFieldMissing", comment: "\(field) is required")
        }
    }
}

/// Network-related errors
enum NetworkError: LocalizedError {
    case noInternetConnection
    case timeout
    case serverUnavailable
    case invalidResponse
    case requestFailed(Int) // HTTP status code
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return NSLocalizedString("Network.Error.NoConnection", comment: "No internet connection")
        case .timeout:
            return NSLocalizedString("Network.Error.Timeout", comment: "Request timed out")
        case .serverUnavailable:
            return NSLocalizedString("Network.Error.ServerUnavailable", comment: "Server is currently unavailable")
        case .invalidResponse:
            return NSLocalizedString("Network.Error.InvalidResponse", comment: "Invalid response from server")
        case .requestFailed(let code):
            return NSLocalizedString("Network.Error.RequestFailed", comment: "Request failed with status code: \(code)")
        }
    }
}

/// Business logic errors
enum BusinessLogicError: LocalizedError {
    case userNotFound
    case insufficientPermissions
    case operationNotAllowed
    case dataCorrupted
    case limitExceeded(String)
    case duplicateEntry(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return NSLocalizedString("Business.Error.UserNotFound", comment: "User not found")
        case .insufficientPermissions:
            return NSLocalizedString("Business.Error.InsufficientPermissions", comment: "Insufficient permissions")
        case .operationNotAllowed:
            return NSLocalizedString("Business.Error.OperationNotAllowed", comment: "Operation not allowed")
        case .dataCorrupted:
            return NSLocalizedString("Business.Error.DataCorrupted", comment: "Data is corrupted")
        case .limitExceeded(let limit):
            return NSLocalizedString("Business.Error.LimitExceeded", comment: "Limit exceeded: \(limit)")
        case .duplicateEntry(let entry):
            return NSLocalizedString("Business.Error.DuplicateEntry", comment: "Duplicate entry: \(entry)")
        }
    }
}