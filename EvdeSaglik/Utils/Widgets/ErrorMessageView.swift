//
//  ErrorMessageView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

/// A standardized error message view that can be used across the app
struct ErrorMessageView: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: ResponsivePadding.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.bodyResponsive)
            
            Text(message)
                .font(.bodyResponsive)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.bodyResponsive)
                }
            }
        }
        .padding(ResponsivePadding.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// A standardized success message view that can be used across the app
struct SuccessMessageView: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: ResponsivePadding.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.bodyResponsive)
            
            Text(message)
                .font(.bodyResponsive)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.bodyResponsive)
                }
            }
        }
        .padding(ResponsivePadding.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// A standardized loading view that can be used across the app
struct StandardLoadingView: View {
    let message: String
    
    init(message: String = NSLocalizedString("Common.Loading", comment: "")) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: ResponsivePadding.medium) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.bodyResponsive)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// A view modifier that automatically displays error and success messages from BaseViewModel
struct MessageDisplayModifier: ViewModifier {
    @ObservedObject var viewModel: BaseViewModel
    
    func body(content: Content) -> some View {
        VStack(spacing: ResponsivePadding.small) {
            content
            
            if let errorMessage = viewModel.errorMessage {
                ErrorMessageView(message: errorMessage) {
                    viewModel.clearMessages()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            if let successMessage = viewModel.successMessage {
                SuccessMessageView(message: successMessage) {
                    viewModel.clearMessages()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .animation(.easeInOut(duration: 0.3), value: viewModel.successMessage)
    }
}

// MARK: - View Extension

extension View {
    /// Adds automatic error and success message display for BaseViewModel
    func messageDisplay(for viewModel: BaseViewModel) -> some View {
        modifier(MessageDisplayModifier(viewModel: viewModel))
    }
}

#Preview {
    VStack(spacing: ResponsivePadding.medium) {
        ErrorMessageView(message: "Bu bir hata mesajıdır")
        SuccessMessageView(message: "İşlem başarıyla tamamlandı")
        StandardLoadingView(message: "Yükleniyor...")
    }
    .padding()
}
