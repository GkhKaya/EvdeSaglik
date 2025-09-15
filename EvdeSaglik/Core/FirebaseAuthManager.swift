//
//  FirebaseAuthManager.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseAuth
import SwiftUI

/// AuthManager handles user authentication using FirebaseAuth.
/// Supports registration, login, password reset, email & password update, and session management.
final class FirebaseAuthManager: ObservableObject {
    
    /// Shared instance for EnvironmentObject usage (optional)
    // static let shared = AuthManager()
    
    @Published var currentUser: User? = Auth.auth().currentUser
    /// Indicates that the last auth action was a successful registration
    @Published var didJustRegister: Bool = false
    
    init() {}
    
    // MARK: - Register User
    /**
     Registers a new user with email and password.
     
     - Parameters:
        - email: User email.
        - password: User password.
        - completion: Completion handler with optional error.
     */
    func register(email: String, password: String, completion: @escaping (AppError?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                self?.currentUser = user
                self?.didJustRegister = true
            }
            if let firebaseError = error as NSError? {
                completion(.authError(.registrationFailed(firebaseError.localizedDescription)))
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Login User
    /**
     Logs in a user with email and password.
     
     - Parameters:
        - email: User email.
        - password: User password.
        - completion: Completion handler with optional error.
     */
    func login(email: String, password: String, completion: @escaping (AppError?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                self?.currentUser = user
            }
            if let firebaseError = error as NSError? {
                completion(.authError(.loginFailed(firebaseError.localizedDescription)))
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Sign Out
    /**
     Signs out the current user.
     
     - Parameter completion: Completion handler with optional error.
     */
    func signOut(completion: @escaping (AppError?) -> Void) {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            completion(nil)
        } catch _ as NSError {
            completion(.authError(.unknown))
        }
    }
    
    // MARK: - Reset Password
    /**
     Sends a password reset email.
     
     - Parameters:
        - email: Email of the user to reset password.
        - completion: Completion handler with optional error.
     */
    func resetPassword(email: String, completion: @escaping (AppError?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let firebaseError = error as NSError? {
                completion(.authError(.passwordResetFailed(firebaseError.localizedDescription)))
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Update Email
    /**
     Updates the email of the currently logged-in user.
     
     - Parameters:
        - newEmail: The new email address.
        - completion: Completion handler with optional error.
     */
    func updateEmail(newEmail: String, completion: @escaping (AppError?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.authError(.unknown))
            return
        }
        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            if let firebaseError = error as NSError? {
                completion(.authError(.emailUpdateFailed(firebaseError.localizedDescription)))
            } else {
                // E-posta doğrulama linki başarıyla gönderildi.
                // Kullanıcıya bu konuda bilgi verilmeli ve e-postasını kontrol etmesi istenmeli.
                completion(nil)
            }
        }
    }
    
    // MARK: - Update Password
    /**
     Updates the password of the currently logged-in user.
     
     - Parameters:
        - newPassword: The new password.
        - completion: Completion handler with optional error.
     */
    func updatePassword(newPassword: String, completion: @escaping (AppError?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.authError(.unknown))
            return
        }
        user.updatePassword(to: newPassword) { error in
            if error != nil {
                completion(.authError(.unknown))
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Check Current User
    /**
     Returns the currently logged-in user (if any).
     
     - Returns: Optional Firebase User
     */
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
}
