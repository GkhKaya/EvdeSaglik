//
//  FirebaseAuthManager.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseAuth
import SwiftUI

// MARK: - Authentication Protocols

/// Protocol for authentication operations
protocol AuthenticationServiceProtocol {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    
    func register(email: String, password: String) async throws
    func login(email: String, password: String) async throws
    func signOut() async throws
    func resetPassword(email: String) async throws
    func updateEmail(_ email: String) async throws
    func updatePassword(_ password: String) async throws
    func deleteAccount() async throws
}

/// AuthManager handles user authentication using FirebaseAuth.
/// Supports registration, login, password reset, email & password update, and session management.
final class FirebaseAuthManager: ObservableObject, AuthenticationServiceProtocol {
    
    /// Shared instance for EnvironmentObject usage (optional)
    // static let shared = AuthManager()
    
    @Published var currentUser: User? = Auth.auth().currentUser
    /// Indicates that the last auth action was a successful registration
    @Published var didJustRegister: Bool = false
    
    /// Computed property for authentication status
    var isAuthenticated: Bool {
        return currentUser != nil
    }
    
    init() {}
    
    // MARK: - Register User
    /**
     Registers a new user with email and password (async version).
     
     - Parameters:
        - email: User email.
        - password: User password.
     - Throws: AppError if the operation fails.
     */
    func register(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await MainActor.run {
                self.currentUser = result.user
                self.didJustRegister = true
            }
        } catch let error as NSError {
            throw AppError.authError(.registrationFailed(error.localizedDescription))
        }
    }
    
    /**
     Registers a new user with email and password (completion handler version - deprecated).
     
     - Parameters:
        - email: User email.
        - password: User password.
        - completion: Completion handler with optional error.
     */
    @available(*, deprecated, message: "Use async version instead")
    func register(email: String, password: String, completion: @escaping (AppError?) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.register(email: email, password: password)
                completion(nil)
            } catch {
                completion(error as? AppError)
            }
        }
    }
    
    // MARK: - Login User
    /**
     Logs in a user with email and password (async version).
     
     - Parameters:
        - email: User email.
        - password: User password.
        - rememberMe: Boolean indicating if user wants to be remembered.
     - Throws: AppError if the operation fails.
     */
    func login(email: String, password: String, rememberMe: Bool) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.currentUser = result.user
                self.setRememberMe(value: rememberMe)
            }
        } catch let error as NSError {
            throw AppError.authError(.loginFailed(error.localizedDescription))
        }
    }

    /// Overload to conform to AuthenticationServiceProtocol
    func login(email: String, password: String) async throws {
        try await login(email: email, password: password, rememberMe: false)
    }
    
    /**
     Logs in a user with email and password (completion handler version - deprecated).
     
     - Parameters:
        - email: User email.
        - password: User password.
        - rememberMe: Boolean indicating if user wants to be remembered.
        - completion: Completion handler with optional error.
     */
    @available(*, deprecated, message: "Use async version instead")
    func login(email: String, password: String, rememberMe: Bool, completion: @escaping (AppError?) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.login(email: email, password: password, rememberMe: rememberMe)
                completion(nil)
            } catch {
                completion(error as? AppError)
            }
        }
    }
    
    // MARK: - Sign Out
    /**
     Signs out the current user (async version).
     
     - Throws: AppError if the operation fails.
     */
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
            await MainActor.run {
                self.currentUser = nil
                self.setRememberMe(value: false) // Clear remember me preference on sign out
            }
        } catch {
            throw AppError.authError(.unknown)
        }
    }
    
    /**
     Signs out the current user (completion handler version - deprecated).
     
     - Parameter completion: Completion handler with optional error.
     */
    @available(*, deprecated, message: "Use async version instead")
    func signOut(completion: @escaping (AppError?) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.signOut()
                completion(nil)
            } catch {
                completion(error as? AppError)
            }
        }
    }
    
    // MARK: - Reset Password
    /**
     Sends a password reset email (async version).
     
     - Parameters:
        - email: Email of the user to reset password.
     - Throws: AppError if the operation fails.
     */
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw AppError.authError(.passwordResetFailed(error.localizedDescription))
        }
    }
    
    /**
     Sends a password reset email (completion handler version - deprecated).
     
     - Parameters:
        - email: Email of the user to reset password.
        - completion: Completion handler with optional error.
     */
    @available(*, deprecated, message: "Use async version instead")
    func resetPassword(email: String, completion: @escaping (AppError?) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.resetPassword(email: email)
                completion(nil)
            } catch {
                completion(error as? AppError)
            }
        }
    }
    
    // MARK: - Update Email
    /**
     Updates the email of the currently logged-in user (completion handler version - deprecated).
     
     - Parameters:
        - newEmail: The new email address.
        - completion: Completion handler with optional error.
     */
    @available(*, deprecated, message: "Use async version instead")
    func updateEmail(newEmail: String, completion: @escaping (AppError?) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.updateEmail(newEmail)
                completion(nil)
            } catch {
                completion(error as? AppError)
            }
        }
    }
    
    /**
     Updates the email of the currently logged-in user (async version).
     
     - Parameter newEmail: The new email address.
     - Throws: AppError if the operation fails.
     */
    func updateEmail(_ newEmail: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AppError.authError(.unknown)
        }
        
        try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = Auth.auth().currentUser
        }
    }
    
    // MARK: - Update Password
    /**
     Updates the password of the currently logged-in user (completion handler version - deprecated).
     
     - Parameters:
        - newPassword: The new password.
        - completion: Completion handler with optional error.
     */
    @available(*, deprecated, message: "Use async version instead")
    func updatePassword(newPassword: String, completion: @escaping (AppError?) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.updatePassword(newPassword)
                completion(nil)
            } catch {
                completion(error as? AppError)
            }
        }
    }
    
    /**
     Updates the password of the currently logged-in user (async version).
     
     - Parameter newPassword: The new password.
     - Throws: AppError if the operation fails.
     */
    func updatePassword(_ newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AppError.authError(.unknown)
        }
        
        try await user.updatePassword(to: newPassword)
    }
    
    
    
    // MARK: - Check Current User
    /**
     Returns the currently logged-in user (if any).
     
     - Returns: Optional Firebase User
     */
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Remember Me Preference
    private let rememberMeKey = "rememberMeUserDefaultKey"
    
    func setRememberMe(value: Bool) {
        UserDefaults.standard.set(value, forKey: rememberMeKey)
    }
    
    func getRememberMe() -> Bool {
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }
    
    // MARK: - Delete Account
    /**
     Deletes the current user's account (async version).
     
     - Throws: AppError if the operation fails
     */
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AppError.authError(.unknown)
        }
        
        try await user.delete()
        await MainActor.run {
            self.currentUser = nil
        }
    }
    
    // Removed checkAndSignOutIfRememberMeFalse() as per user request to simplify startup flow.
}

