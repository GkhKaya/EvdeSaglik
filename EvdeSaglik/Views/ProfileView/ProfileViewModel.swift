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
        guard !newEmail.isEmpty else {
            errorMessage = NSLocalizedString("Profile.Error.EmptyEmail", comment: "")
            return
        }
        
        guard newEmail.contains("@") else {
            errorMessage = NSLocalizedString("Profile.Error.InvalidEmail", comment: "")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.updateEmail(newEmail)
            successMessage = NSLocalizedString("Profile.Success.EmailChanged", comment: "")
            newEmail = ""
            showingChangeEmail = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func changePassword() async {
        guard !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty else {
            errorMessage = NSLocalizedString("Profile.Error.EmptyFields", comment: "")
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = NSLocalizedString("Profile.Error.PasswordMismatch", comment: "")
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = NSLocalizedString("Profile.Error.WeakPassword", comment: "")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.updatePassword(newPassword)
            successMessage = NSLocalizedString("Profile.Success.PasswordChanged", comment: "")
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            showingChangePassword = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func resetUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete all user data from Firestore
            try await firestoreManager.deleteUserData(userId: authManager.currentUser?.uid ?? "")
            successMessage = NSLocalizedString("Profile.Success.DataReset", comment: "")
            showingResetData = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First delete user data from Firestore
            try await firestoreManager.deleteUserData(userId: authManager.currentUser?.uid ?? "")
            
            // Then delete the Firebase Auth account
            try await authManager.deleteAccount()
            
            successMessage = NSLocalizedString("Profile.Success.AccountDeleted", comment: "")
            showingDeleteAccount = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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

