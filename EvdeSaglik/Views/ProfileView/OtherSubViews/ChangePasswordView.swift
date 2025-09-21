//
//  ChangePasswordView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Change Password ViewModel
class ChangePasswordViewModel: BaseViewModel {
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    private let authManager: FirebaseAuthManager
    
    init(authManager: FirebaseAuthManager) {
        self.authManager = authManager
    }
    
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
            
            // Reset fields
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @StateObject private var viewModel: ChangePasswordViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCurrentPasswordFocused: Bool
    @FocusState private var isNewPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool
    
    init(authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: ChangePasswordViewModel(authManager: authManager))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ResponsivePadding.large) {
                    VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                        Text(NSLocalizedString("Profile.ChangePassword.Title", comment: ""))
                            .font(.title2Responsive)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("Profile.ChangePassword.Description", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                        
                        CustomTextField(
                            title: NSLocalizedString("Profile.ChangePassword.Current", comment: ""),
                            placeholder: NSLocalizedString("Profile.ChangePassword.CurrentPlaceholder", comment: ""),
                            icon: "key",
                            text: $viewModel.currentPassword,
                            isMultiline: false
                        )
                        .focused($isCurrentPasswordFocused)
                        .textContentType(.password)
                        
                        CustomTextField(
                            title: NSLocalizedString("Profile.ChangePassword.New", comment: ""),
                            placeholder: NSLocalizedString("Profile.ChangePassword.NewPlaceholder", comment: ""),
                            icon: "key.fill",
                            text: $viewModel.newPassword,
                            isMultiline: false
                        )
                        .focused($isNewPasswordFocused)
                        .textContentType(.newPassword)
                        
                        CustomTextField(
                            title: NSLocalizedString("Profile.ChangePassword.Confirm", comment: ""),
                            placeholder: NSLocalizedString("Profile.ChangePassword.ConfirmPlaceholder", comment: ""),
                            icon: "key.fill",
                            text: $viewModel.confirmPassword,
                            isMultiline: false
                        )
                        .focused($isConfirmPasswordFocused)
                        .textContentType(.newPassword)
                    }
                    
                    Spacer(minLength: ResponsivePadding.large)
                    
                    Button(action: {
                        Task { await viewModel.changePassword() }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(NSLocalizedString("Profile.ChangePassword.Update", comment: ""))
                                .font(.bodyResponsive)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(ResponsivePadding.medium)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundStyle(.white)
                    }
                    .disabled(viewModel.isLoading || viewModel.currentPassword.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty)
                }
                .padding(ResponsivePadding.large)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle(NSLocalizedString("Profile.ChangePassword.Title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(NSLocalizedString("Profile.Alert.Error", comment: ""), isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(NSLocalizedString("Common.OK", comment: "")) {
                    viewModel.clearMessages()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert(NSLocalizedString("Profile.Alert.Success", comment: ""), isPresented: .constant(viewModel.successMessage != nil)) {
                Button(NSLocalizedString("Common.OK", comment: "")) {
                    viewModel.clearMessages()
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
        }
    }
}
