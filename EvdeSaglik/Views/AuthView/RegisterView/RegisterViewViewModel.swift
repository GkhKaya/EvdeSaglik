//
//  RegisterViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine
import SwiftUI // Added for Color
import EvdeSaglik // Import the main module to access PasswordStrength

// Removed PasswordStrength enum - moved to its own file

final class RegisterViewViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var shouldNavigateToLogin: Bool = false
    @Published var didRegisterSuccessfully: Bool = false // New property
    @Published var passwordStrength: PasswordStrength = .none // Password strength indicator
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return isEmailValid && isPasswordValid && isConfirmPasswordValid
    }
    
    var emailValidationMessage: String {
        if email.isEmpty { return "" }
        return isEmailValid ? "" : NSLocalizedString("Register.EmailHint.Invalid", comment: "Invalid Email Format")
    }
    
    var passwordValidationMessage: String {
        if password.isEmpty { return "" }
        var messages: [String] = []
        if password.count < 8 {
            messages.append(NSLocalizedString("Register.PasswordHint.MinLength", comment: "Min 8 characters"))
        }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            messages.append(NSLocalizedString("Register.PasswordHint.Uppercase", comment: "Uppercase letter"))
        }
        if password.range(of: "[a-z]", options: .regularExpression) == nil {
            messages.append(NSLocalizedString("Register.PasswordHint.Lowercase", comment: "Lowercase letter"))
        }
        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            messages.append(NSLocalizedString("Register.PasswordHint.Number", comment: "A number"))
        }
        if password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil {
            messages.append(NSLocalizedString("Register.PasswordHint.SpecialCharacter", comment: "A special character"))
        }
        return messages.joined(separator: ", ")
    }
    
    private var isEmailValid: Bool {
        do {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let regex = try NSRegularExpression(pattern: emailRegex, options: .caseInsensitive)
            return regex.firstMatch(in: email, options: [], range: NSRange(location: 0, length: email.utf16.count)) != nil
        } catch {
            print("Regex error: \(error.localizedDescription)")
            return false
        }
    }
    
    private var isPasswordValid: Bool {
        let minLength = password.count >= 8
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialCharacter = password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil
        
        return minLength && hasUppercase && hasLowercase && hasNumber && hasSpecialCharacter
    }
    
    private var isConfirmPasswordValid: Bool {
        return password == confirmPassword && !confirmPassword.isEmpty
    }
    
    // MARK: - Initialization
    init() {
        setupValidation()
    }
    
    // MARK: - Public Methods
    func register(authManager: FirebaseAuthManager) {
        guard isFormValid else {
            errorMessage = NSLocalizedString("Register.Error.InvalidForm", comment: "Invalid form error")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        authManager.register(email: email, password: password) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleAuthError(error)
                } else {
                    // If error is nil, registration was successful
                    self?.didRegisterSuccessfully = true // Set to true on success
                }
            }
        }
    }
    
    func navigateToLogin() {
        shouldNavigateToLogin = true
    }
    
    // MARK: - Private Methods
    private func setupValidation() {
        // Clear error message when user starts typing
        Publishers.CombineLatest3($email, $password, $confirmPassword)
            .sink { [weak self] _, password, _ in
                self?.errorMessage = ""
                self?.calculatePasswordStrength(password: password)
            }
            .store(in: &cancellables)
    }
    
    private func calculatePasswordStrength(password: String) {
        var strengthScore = 0
        
        if password.count >= 8 { strengthScore += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strengthScore += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { strengthScore += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { strengthScore += 1 }
        if password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { strengthScore += 1 }
        
        switch strengthScore {
        case 0: self.passwordStrength = .none
        case 1...2: self.passwordStrength = .weak
        case 3: self.passwordStrength = .medium
        case 4: self.passwordStrength = .strong
        case 5: self.passwordStrength = .veryStrong
        default: self.passwordStrength = .none
        }
    }
    
    private func handleAuthError(_ error: AppError) {
        switch error {
        case .authError(let authError):
            switch authError {
            case .registrationFailed(let message):
                // Check for specific Firebase error codes in the message
                if message.contains("email-already-in-use") {
                    errorMessage = NSLocalizedString("Register.Error.EmailAlreadyInUse", comment: "Email already in use")
                } else if message.contains("invalid-email") {
                    errorMessage = NSLocalizedString("Register.Error.InvalidEmail", comment: "Invalid email")
                } else if message.contains("weak-password") {
                    errorMessage = NSLocalizedString("Register.Error.WeakPassword", comment: "Weak password")
                } else {
                    errorMessage = NSLocalizedString("Register.Error.Generic", comment: "Generic registration error")
                }
            default:
                errorMessage = NSLocalizedString("Register.Error.Generic", comment: "Generic registration error")
            }
        default:
            errorMessage = NSLocalizedString("Register.Error.Generic", comment: "Generic registration error")
        }
    }
}