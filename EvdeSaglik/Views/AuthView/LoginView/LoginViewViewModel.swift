//
//  LoginViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine


final class LoginViewViewModel : ObservableObject {
    // Inputs
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = true
    @Published var isPasswordHidden: Bool = true
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Validation
    @Published private(set) var canSubmit: Bool = false
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        Publishers.CombineLatest($email, $password)
            .map { [weak self] email, password in
                guard let self = self else { return false }
                return self.isValidEmail(email) && self.isValidPassword(password)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$canSubmit)
    }
    
    // MARK: - Intent
    func onLoginTapped() {
        errorMessage = nil
        guard canSubmit else {
            errorMessage = NSLocalizedString("Login.Validation.Invalid", comment: "Invalid login input")
            return
        }
        // UI-only: fake delay to show loading state
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.isLoading = false
            // No Firebase call here; navigation will be handled by parent when integrated
        }
    }
    
    func onRegisterTapped() {
        // Hook for navigation to register screen
    }
    
    func onForgotPasswordTapped() {
        // Hook for navigation to forgot password screen
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
