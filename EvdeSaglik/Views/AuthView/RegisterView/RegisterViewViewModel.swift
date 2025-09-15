//
//  RegisterViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine

final class RegisterViewViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var shouldNavigateToLogin: Bool = false
    @Published var didRegisterSuccessfully: Bool = false // New property
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return isEmailValid && isPasswordValid && isConfirmPasswordValid
    }
    
    private var isEmailValid: Bool {
        return email.contains("@") && email.contains(".")
    }
    
    private var isPasswordValid: Bool {
        return password.count >= 6
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
            .sink { [weak self] _, _, _ in
                self?.errorMessage = ""
            }
            .store(in: &cancellables)
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