import Foundation

enum AppError: LocalizedError {
    case authError(AuthError)
    case firestoreError(FirestoreError)
    // case aiBackendError(AIBackendError) // Uncomment if AI/Backend errors are needed

    var errorDescription: String? {
        switch self {
        case .authError(let error):
            return error.errorDescription
        case .firestoreError(let error):
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

/*
// Örnek AI/Backend Hata Enum'u (isteğe bağlı)
enum AIBackendError: LocalizedError {
    case predictionFailed(String)
    case serverError(String)
    case invalidInput(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .predictionFailed(let message):
            return NSLocalizedString("AIBackend.Error.PredictionFailed", comment: message)
        case .serverError(let message):
            return NSLocalizedString("AIBackend.Error.ServerError", comment: message)
        case .invalidInput(let message):
            return NSLocalizedString("AIBackend.Error.InvalidInput", comment: message)
        case .unknown:
            return NSLocalizedString("AIBackend.Error.Unknown", comment: "Bilinmeyen bir AI/Backend hatası oluştu.")
        }
    }
}
*/
