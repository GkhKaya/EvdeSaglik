//
//  LoginView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct LoginView: View {
    // MARK: - Properties
    @ObservedObject var viewModel = LoginViewViewModel()
    @EnvironmentObject var authManager: FirebaseAuthManager
    let onShowRegister: (() -> Void)?
    
    init(onShowRegister: (() -> Void)? = nil) {
        self.onShowRegister = onShowRegister
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    formSection
                    actionSection
                    footerSection
                }
                .padding(.horizontal, ResponsivePadding.large)
            }
        }
        .onReceive(viewModel.$shouldNavigateToRegister) { shouldNavigate in
            if shouldNavigate {
                onShowRegister?()
                viewModel.shouldNavigateToRegister = false
            }
        }
    }
}

// MARK: - View Components
private extension LoginView {
    
    /// Header section with title and subtitle
    var headerSection: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            Text(NSLocalizedString("Login.Title", comment: "Main title"))
                .font(.title1Responsive)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(NSLocalizedString("Login.Subtitle", comment: "Subtitle"))
                .font(.bodyResponsive)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, ResponsivePadding.extraLarge * 2)
        .padding(.bottom, ResponsivePadding.extraLarge)
    }
    
    /// Form section with input fields and options
    var formSection: some View {
        VStack(spacing: ResponsivePadding.medium) {
            emailField
            passwordField
            optionsRow
            errorMessage
        }
    }
    
    /// Email input field
    var emailField: some View {
        CustomTextField(
            title: NSLocalizedString("Login.Email.Label", comment: "Email label"),
            placeholder: NSLocalizedString("Login.Email.Placeholder", comment: "Email placeholder"),
            icon: "envelope",
            text: $viewModel.email
        )
    }
    
    /// Password input field with toggle
    var passwordField: some View {
        CustomTextField(
            title: NSLocalizedString("Login.Password.Label", comment: "Password label"),
            placeholder: NSLocalizedString("Login.Password.Placeholder", comment: "Password placeholder"),
            icon: "lock",
            text: $viewModel.password,
            isSecure: true,
            showPasswordToggle: true
        )
    }
    
    /// Remember me checkbox and forgot password link
    var optionsRow: some View {
        HStack {
            CustomCheckbox(
                title: NSLocalizedString("Login.RememberMe", comment: "Remember me"),
                isChecked: $viewModel.rememberMe
            )
            
            Spacer()
            
            Button(action: { viewModel.forgotPassword(authManager: authManager) }) {
                Text(NSLocalizedString("Login.ForgotPassword", comment: "Forgot password"))
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.top, ResponsivePadding.small)
    }
    
    /// Error message display
    @ViewBuilder
    var errorMessage: some View {
        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .font(.subheadlineResponsive)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, ResponsivePadding.small)
        }
    }
    
    /// Action section with login button
    var actionSection: some View {
        CustomButton(
            title: NSLocalizedString("Login.SignIn", comment: "Sign in button"),
            action: { viewModel.signIn(authManager: authManager) },
            isEnabled: viewModel.canSubmit,
            isLoading: viewModel.isLoading
        )
        .padding(.top, ResponsivePadding.large)
    }
    
    /// Footer section with sign up link
    var footerSection: some View {
        HStack(spacing: 4) {
            Text(NSLocalizedString("Login.SignUp.Title", comment: "Sign up title"))
                .font(.subheadlineResponsive)
                .foregroundStyle(.secondary)
            
            Button(action: { viewModel.shouldNavigateToRegister = true }) {
                Text(NSLocalizedString("Login.SignUp.Action", comment: "Sign up action"))
                    .font(.subheadlineResponsive)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, ResponsivePadding.extraLarge)
        .padding(.bottom, ResponsivePadding.large)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(FirebaseAuthManager())
        .environmentObject(FirestoreManager())
        .environmentObject(AppStateHolder())
        .environmentObject(UserManager())
}