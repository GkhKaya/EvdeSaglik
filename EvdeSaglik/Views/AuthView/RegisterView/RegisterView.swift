//
//  RegisterView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI
import EvdeSaglik // Import the main module to access PasswordStrength

struct RegisterView: View {
    // MARK: - Properties
    @ObservedObject var viewModel = RegisterViewViewModel()
    @EnvironmentObject var authManager: FirebaseAuthManager
    @Environment(\.dismiss) var dismiss // Add dismiss environment variable
    
    // Remove onBackToLogin property and init parameter since sheet dismissal will handle navigation
    // let onBackToLogin: (() -> Void)?
    
    // init(onBackToLogin: (() -> Void)? = nil) {
    //     self.onBackToLogin = onBackToLogin
    // }
    
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
        .onReceive(viewModel.$shouldNavigateToLogin) { shouldNavigate in
            if shouldNavigate {
                // Dismiss the sheet to go back to LoginView
                dismiss()
                viewModel.shouldNavigateToLogin = false
            }
        }
        .onReceive(viewModel.$didRegisterSuccessfully) { didRegister in
            if didRegister {
                // Dismiss the sheet on successful registration
                dismiss()
                viewModel.didRegisterSuccessfully = false // Reset the flag
            }
        }
    }
}

// MARK: - View Components
private extension RegisterView {
    
    /// Header section with title and subtitle
    var headerSection: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            Text(NSLocalizedString("Register.Title", comment: "Main title"))
                .font(.title1Responsive)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(NSLocalizedString("Register.Subtitle", comment: "Subtitle"))
                .font(.bodyResponsive)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, ResponsivePadding.extraLarge * 2)
        .padding(.bottom, ResponsivePadding.extraLarge)
    }
    
    /// Form section with input fields
    var formSection: some View {
        VStack(spacing: ResponsivePadding.medium) {
            emailField
            passwordField
            confirmPasswordField
            errorMessage
        }
    }
    
    /// Email input field
    var emailField: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.xSmall) {
            CustomTextField(
                title: NSLocalizedString("Register.Email.Label", comment: "Email label"),
                placeholder: NSLocalizedString("Register.Email.Placeholder", comment: "Email placeholder"),
                icon: "envelope",
                text: $viewModel.email
            )
            if !viewModel.emailValidationMessage.isEmpty {
                Text(viewModel.emailValidationMessage)
                    .font(Font.captionResponsive) // Explicitly specify Font.captionResponsive
                    .foregroundStyle(.red)
            }
        }
    }
    
    /// Password input field with toggle
    var passwordField: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.xSmall) {
            CustomTextField(
                title: NSLocalizedString("Register.Password.Label", comment: "Password label"),
                placeholder: NSLocalizedString("Register.Password.Placeholder", comment: "Password placeholder"),
                icon: "lock",
                text: $viewModel.password,
                isSecure: true,
                showPasswordToggle: true
            )
            if !viewModel.passwordValidationMessage.isEmpty {
                Text(viewModel.passwordValidationMessage)
                    .font(Font.captionResponsive) // Explicitly specify Font.captionResponsive
                    .foregroundStyle(.red)
            }
            
            // Password Strength Indicator
            if !viewModel.password.isEmpty {
                HStack(spacing: ResponsivePadding.small) {
                    ProgressView(value: Double(viewModel.passwordStrength.rawValue), total: 4.0) // Changed total to a direct Double value
                        .progressViewStyle(LinearProgressViewStyle(tint: viewModel.passwordStrength.color))
                        .frame(height: 8)
                        .cornerRadius(ResponsiveRadius.small)
                    Text(viewModel.passwordStrength.localizedString)
                        .font(Font.captionResponsive)
                        .foregroundStyle(viewModel.passwordStrength.color)
                }
                .padding(.horizontal, ResponsivePadding.small)
            }
        }
    }
    
    /// Confirm password input field with toggle
    var confirmPasswordField: some View {
        CustomTextField(
            title: NSLocalizedString("Register.ConfirmPassword.Label", comment: "Confirm password label"),
            placeholder: NSLocalizedString("Register.ConfirmPassword.Placeholder", comment: "Confirm password placeholder"),
            icon: "lock",
            text: $viewModel.confirmPassword,
            isSecure: true,
            showPasswordToggle: true
        )
    }
    
    /// Error message display
    var errorMessage: some View {
        Group {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, ResponsivePadding.small)
            }
        }
    }
    
    /// Action section with register button
    var actionSection: some View {
        VStack(spacing: ResponsivePadding.medium) {
            registerButton
        }
        .padding(.top, ResponsivePadding.large)
    }
    
    /// Register button
    var registerButton: some View {
        CustomButton(
            title: NSLocalizedString("Register.Button", comment: "Register button"),
            action: { viewModel.register(authManager: authManager) },
            isEnabled: viewModel.isFormValid,
            isLoading: viewModel.isLoading
        )
    }
    
    /// Footer section with login link
    var footerSection: some View {
        VStack(spacing: ResponsivePadding.medium) {
            loginLink
        }
        .padding(.top, ResponsivePadding.extraLarge)
        .padding(.bottom, ResponsivePadding.large)
    }
    
    /// Login link for existing users
    var loginLink: some View {
        Button(action: { viewModel.navigateToLogin() }) {
            HStack(spacing: ResponsivePadding.xSmall) {
                Text(NSLocalizedString("Register.Login.Prefix", comment: "Login prefix"))
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.secondary)
                
                Text(NSLocalizedString("Register.Login.Link", comment: "Login link"))
                    .font(.subheadlineResponsive)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(FirebaseAuthManager())
}