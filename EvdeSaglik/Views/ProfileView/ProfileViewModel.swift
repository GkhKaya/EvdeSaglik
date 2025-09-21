//
//  ProfileViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI
import FirebaseAuth

final class ProfileViewModel: BaseViewModel {
    @Published var showingPersonalization: Bool = false
    @Published var showingChangeEmail: Bool = false
    @Published var showingChangePassword: Bool = false
    @Published var showingDeleteAccount: Bool = false
    @Published var showingResetData: Bool = false
    
    // Selection state
    @Published var selectedCategory: String = ""
    
    // Account management
    @Published var newEmail: String = ""
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    private let authManager: FirebaseAuthManager
    private let firestoreManager: FirestoreManager
    
    init(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        self.authManager = authManager
        self.firestoreManager = firestoreManager
    }
    
    // MARK: - Account Management
    
    @MainActor
    func changeEmail() async {
        // Validation using ValidationHelper
        if let validationError = ValidationHelper.validateEmail(newEmail) {
            handleError(AppError.validationError(validationError))
            return
        }
        
        performAsyncOperation(
            operation: {
                try await self.authManager.updateEmail(self.newEmail)
                return true
            },
            context: "ProfileViewModel.changeEmail",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("Profile.Success.EmailChanged", comment: ""))
                self?.newEmail = ""
                self?.showingChangeEmail = false
            }
        )
    }
    
    @MainActor
    func changePassword() async {
        // Validation using ValidationHelper
        if let validationError = ValidationHelper.validatePassword(newPassword) {
            handleError(AppError.validationError(validationError))
            return
        }
        if let validationError = ValidationHelper.validatePasswordConfirmation(password: newPassword, confirmPassword: confirmPassword) {
            handleError(AppError.validationError(validationError))
            return
        }
        
        performAsyncOperation(
            operation: {
                try await self.authManager.updatePassword(self.newPassword)
                return true
            },
            context: "ProfileViewModel.changePassword",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("Profile.Success.PasswordChanged", comment: ""))
                self?.currentPassword = ""
                self?.newPassword = ""
                self?.confirmPassword = ""
                self?.showingChangePassword = false
            }
        )
    }
    
    @MainActor
    func resetUserData() async {
        performAsyncOperation(
            operation: {
                // Delete all user data from Firestore
                try await self.firestoreManager.deleteUserData(userId: self.authManager.currentUser?.uid ?? "")
                return true
            },
            context: "ProfileViewModel.resetUserData",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("Profile.Success.DataReset", comment: ""))
                self?.showingResetData = false
            }
        )
    }
    
    @MainActor
    func deleteAccount() async {
        performAsyncOperation(
            operation: {
                // First delete user data from Firestore
                try await self.firestoreManager.deleteUserData(userId: self.authManager.currentUser?.uid ?? "")
                
                // Then delete the Firebase Auth account
                try await self.authManager.deleteAccount()
                
                return true
            },
            context: "ProfileViewModel.deleteAccount",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("Profile.Success.AccountDeleted", comment: ""))
                self?.showingDeleteAccount = false
            }
        )
    }
    
    override func clearMessages() {
        super.clearMessages()
    }
    
    // MARK: - Selection Management
    
    func selectCategory(_ category: String) {
        selectedCategory = category
    }
    
    func isCategorySelected(_ category: String) -> Bool {
        return selectedCategory == category
    }
    
    // MARK: - Computed Properties
    
    var currentUserEmail: String {
        authManager.currentUser?.email ?? ""
    }
    
    var currentUserName: String {
        authManager.currentUser?.displayName ?? ""
    }
}

