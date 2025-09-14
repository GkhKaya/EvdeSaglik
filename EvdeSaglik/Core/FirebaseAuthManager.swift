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
    
    init() {}
    
    // MARK: - Register User
    /**
     Registers a new user with email and password.
     
     - Parameters:
        - email: User email.
        - password: User password.
        - completion: Completion handler with optional error.
     */
    func register(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                self?.currentUser = user
            }
            completion(error)
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
    func login(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                self?.currentUser = user
            }
            completion(error)
        }
    }
    
    // MARK: - Sign Out
    /**
     Signs out the current user.
     
     - Parameter completion: Completion handler with optional error.
     */
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            completion(nil)
        } catch let signOutError {
            completion(signOutError)
        }
    }
    
    // MARK: - Reset Password
    /**
     Sends a password reset email.
     
     - Parameters:
        - email: Email of the user to reset password.
        - completion: Completion handler with optional error.
     */
    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            completion(error)
        }
    }
    
    // MARK: - Update Email
    /**
     Updates the email of the currently logged-in user.
     
     - Parameters:
        - newEmail: The new email address.
        - completion: Completion handler with optional error.
     */
    func updateEmail(newEmail: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No logged-in user"]))
            return
        }
        user.updateEmail(to: newEmail) { error in
            if error == nil {
                self.currentUser = Auth.auth().currentUser
            }
            completion(error)
        }
    }
    
    // MARK: - Update Password
    /**
     Updates the password of the currently logged-in user.
     
     - Parameters:
        - newPassword: The new password.
        - completion: Completion handler with optional error.
     */
    func updatePassword(newPassword: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No logged-in user"]))
            return
        }
        user.updatePassword(to: newPassword) { error in
            completion(error)
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
