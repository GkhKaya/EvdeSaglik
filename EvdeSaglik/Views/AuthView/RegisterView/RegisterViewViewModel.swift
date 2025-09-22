//
//  RegisterViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine
import SwiftUI

final class RegisterViewViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var didRegisterSuccessfully: Bool = false
    @Published var passwordStrength: PasswordStrength = .none
    @Published var isPasswordVisible: Bool = false
    @Published var isConfirmPasswordVisible: Bool = false
    
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
    override init() {
        super.init()
        setupValidation()
    }
    
    // MARK: - Public Methods
    func register(authManager: FirebaseAuthManager) {
        // ✅ YENİ: Use standardized validation
        guard validateRegistrationForm(email: email, password: password, confirmPassword: confirmPassword) else {
            return // Error already handled by BaseViewModel
        }
        
        guard isFormValid else {
            handleValidationError(.invalidFormat("Registration form"))
            return
        }
        
        isLoading = true
        clearMessages()
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await authManager.register(email: email, password: password)
                await MainActor.run {
                    self.didRegisterSuccessfully = true
                    self.handleSuccess(NSLocalizedString("Register.Success", comment: "Successfully registered"))
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, context: "Registration")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupValidation() {
        // Clear error message when user starts typing
        Publishers.CombineLatest3($email, $password, $confirmPassword)
            .sink { [weak self] _, password, _ in
                self?.clearMessages()
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
        case 1: self.passwordStrength = .weak
        case 2: self.passwordStrength = .medium
        case 3: self.passwordStrength = .strong
        case 4...5: self.passwordStrength = .veryStrong
        default: self.passwordStrength = .none
        }
    }
}