//
//  LoginViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine


final class LoginViewViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var shouldNavigateToRegister: Bool = false
    
    // MARK: - Computed Properties
    @Published private(set) var canSubmit: Bool = false
    
    // MARK: - Private Properties
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    init() {
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
    
    private func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Public Methods
    func signIn(authManager: FirebaseAuthManager) {
        guard canSubmit else {
            errorMessage = NSLocalizedString("Login.Validation.Invalid", comment: "Invalid login input")
            return
        }
        
        clearError()
        isLoading = true
        
        authManager.login(email: email, password: password, rememberMe: rememberMe) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleError(error)
                }
            }
        }
    }
    
    func forgotPassword(authManager: FirebaseAuthManager) {
        guard isValidEmail(email) else {
            errorMessage = NSLocalizedString("Login.ForgotPassword.InvalidEmail", comment: "Invalid email for reset")
            return
        }
        
        clearError()
        
        authManager.resetPassword(email: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError(error)
                } else {
                    self?.errorMessage = NSLocalizedString("Login.ForgotPassword.Success", comment: "Password reset email sent")
                }
            }
        }
    }
    
    private func handleError(_ error: AppError) {
        switch error {
        case .authError(let authError):
            switch authError {
            case .loginFailed(let message):
                errorMessage = message
            case .passwordResetFailed(let message):
                errorMessage = message
            default:
                errorMessage = NSLocalizedString("Login.Error.Generic", comment: "Generic login error")
            }
        default:
            errorMessage = NSLocalizedString("Login.Error.Generic", comment: "Generic login error")
        }
    }
    
    // MARK: - Validation Helpers
    private func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }
}
