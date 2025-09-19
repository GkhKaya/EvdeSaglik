//
//  BaseViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

// MARK: - ViewModel Protocols

/// Protocol for ViewModels that handle user data
protocol UserDataViewModelProtocol: ObservableObject {
    var userData: UserModel? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func loadUserData() async
    func saveUserData() async
    func clearError()
}

/// Protocol for ViewModels that handle AI operations
protocol AIViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var resultText: String { get }
    
    func processRequest(input: String) async
    func clearResult()
    func clearError()
}

/// Protocol for ViewModels that handle history data
protocol HistoryViewModelProtocol: ObservableObject {
    associatedtype HistoryItem: UserHistoryDocument
    
    var historyItems: [HistoryItem] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func loadHistory(userId: String) async
    func deleteItem(_ itemId: String) async
    func clearError()
}

/// Base ViewModel class that provides common functionality for all ViewModels.
/// Includes standardized error handling, loading states, and common UI state management.
class BaseViewModel: ObservableObject {
    
    // MARK: - Common Published Properties
    
    /// Indicates if the ViewModel is currently performing an async operation
    @Published var isLoading: Bool = false
    
    /// Current error message to display to the user
    @Published var errorMessage: String? = nil
    
    /// Success message to display to the user (for operations like save, update, etc.)
    @Published var successMessage: String? = nil
    
    // MARK: - Error Handling
    
    /// Handles errors in a standardized way across all ViewModels
    /// - Parameter error: The error to handle
    /// - Parameter context: Optional context string for debugging
    func handleError(_ error: Error, context: String? = nil) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            let errorMessage: String
            if let appError = error as? AppError {
                errorMessage = appError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            
            self.errorMessage = errorMessage
            
            // Log error for debugging
            if let context = context {
                print("❌ Error in \(context): \(errorMessage)")
            } else {
                print("❌ Error: \(errorMessage)")
            }
            
            // Auto-clear error message after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if self.errorMessage == errorMessage {
                    self.errorMessage = nil
                }
            }
        }
    }
    
    /// Handles successful operations with optional success message
    /// - Parameter message: Optional success message to display
    /// - Parameter autoClear: Whether to automatically clear the message after 3 seconds
    func handleSuccess(_ message: String? = nil, autoClear: Bool = true) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = nil
            
            if let message = message {
                self.successMessage = message
                
                if autoClear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if self.successMessage == message {
                            self.successMessage = nil
                        }
                    }
                }
            }
        }
    }
    
    /// Clears all messages (error and success)
    func clearMessages() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }
    }
    
    /// Sets loading state
    /// - Parameter loading: The loading state to set
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    // MARK: - Async Operation Wrapper
    
    /// Wraps an async operation with standardized error handling and loading state management
    /// - Parameters:
    ///   - operation: The async operation to perform
    ///   - context: Optional context string for debugging
    func performAsyncOperation<T>(
        operation: @escaping () async throws -> T,
        context: String? = nil,
        onSuccess: ((T) -> Void)? = nil
    ) {
        Task {
            await MainActor.run {
                self.isLoading = true
                self.clearMessages()
            }
            
            do {
                let result = try await operation()
                await MainActor.run {
                    self.handleSuccess()
                    onSuccess?(result)
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, context: context)
                }
            }
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Validates email format
    /// - Parameter email: Email to validate
    /// - Returns: True if email is valid
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    /// Validates password strength
    /// - Parameter password: Password to validate
    /// - Returns: True if password meets minimum requirements
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    /// Validates that a string is not empty or whitespace
    /// - Parameter text: Text to validate
    /// - Returns: True if text is not empty
    func isNotEmpty(_ text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Convenience Extensions

extension BaseViewModel {
    
    /// Quick error handling for common scenarios
    func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.isLoading = false
        }
    }
    
    /// Quick success handling for common scenarios
    func showSuccess(_ message: String) {
        DispatchQueue.main.async {
            self.successMessage = message
            self.isLoading = false
            self.errorMessage = nil
        }
    }
}
