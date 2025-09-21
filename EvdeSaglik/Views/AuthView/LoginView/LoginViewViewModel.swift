//
//  LoginViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine

final class LoginViewViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = true
    @Published var shouldNavigateToRegister: Bool = false
    
    // MARK: - Computed Properties
    @Published private(set) var canSubmit: Bool = false
    
    // MARK: - Private Properties
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupValidation()
    }
    
    // MARK: - Private Methods
    private func setupValidation() {
        Publishers.CombineLatest($email, $password)
            .map { [weak self] email, password in
                guard let self = self else { return false }
                return self.isValidEmail(email) && self.isValidPassword(password)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$canSubmit)
    }
    
    // MARK: - Public Methods
    func signIn(authManager: FirebaseAuthManager) {
        // ✅ YENİ: Use standardized validation
        guard validateLoginForm(email: email, password: password) else {
            return // Error already handled by BaseViewModel
        }
        
        guard canSubmit else {
            handleValidationError(.invalidFormat("Login form"))
            return
        }
        
        clearMessages()
        isLoading = true
        
        Task {
            do {
                try await authManager.login(email: email, password: password, rememberMe: rememberMe)
                await MainActor.run {
                    self.handleSuccess(NSLocalizedString("Login.Success", comment: "Successfully logged in"))
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, context: "Login")
                }
            }
        }
    }
    
    func forgotPassword(authManager: FirebaseAuthManager) {
        // ✅ YENİ: Use standardized email validation
        if let error = ValidationHelper.validateEmail(email) {
            handleValidationError(error)
            return
        }
        
        clearMessages()
        
        Task {
            do {
                try await authManager.resetPassword(email: email)
                await MainActor.run {
                    self.handleSuccess(NSLocalizedString("Login.ForgotPassword.Success", comment: "Password reset email sent"))
                }
            } catch {
                await MainActor.run {
                    self.handleError(error, context: "PasswordReset")
                }
            }
        }
    }
    
    func navigateToRegister() {
        shouldNavigateToRegister = true
    }
}