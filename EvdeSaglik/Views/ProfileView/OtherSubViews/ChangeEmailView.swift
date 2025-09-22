//
//  ChangeEmailView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Change Email ViewModel
class ChangeEmailViewModel: BaseViewModel {
    @Published var newEmail: String = ""
    
    private let authManager: FirebaseAuthManager
    
    init(authManager: FirebaseAuthManager) {
        self.authManager = authManager
    }
    
    func changeEmail() async {
        guard !newEmail.isEmpty else {
            errorMessage = NSLocalizedString("Profile.Error.EmptyEmail", comment: "")
            return
        }
        
        guard isValidEmail(newEmail) else {
            errorMessage = NSLocalizedString("Profile.Error.InvalidEmail", comment: "")
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            try await authManager.updateEmail(newEmail)
            await MainActor.run {
                self.successMessage = NSLocalizedString("Profile.Success.EmailChanged", comment: "")
                self.newEmail = ""
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    override func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Change Email View
struct ChangeEmailView: View {
    @StateObject private var viewModel: ChangeEmailViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool
    
    init(authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: ChangeEmailViewModel(authManager: authManager))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ResponsivePadding.large) {
                    VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                        Text(NSLocalizedString("Profile.ChangeEmail.Title", comment: ""))
                            .font(.title2Responsive)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("Profile.ChangeEmail.Description", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                        
                        CustomTextField(
                            title: NSLocalizedString("Profile.ChangeEmail.NewEmail", comment: ""),
                            placeholder: NSLocalizedString("Profile.ChangeEmail.Placeholder", comment: ""),
                            icon: "envelope",
                            text: $viewModel.newEmail,
                            isMultiline: false
                        )
                        .focused($isEmailFocused)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    }
                    
                    Spacer(minLength: ResponsivePadding.large)
                    
                    Button(action: {
                        Task { await viewModel.changeEmail() }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(NSLocalizedString("Profile.ChangeEmail.Update", comment: ""))
                                .font(.bodyResponsive)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(ResponsivePadding.medium)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundStyle(.white)
                    }
                    .disabled(viewModel.isLoading || viewModel.newEmail.isEmpty)
                }
                .padding(ResponsivePadding.large)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle(NSLocalizedString("Profile.ChangeEmail.Title", comment: ""))
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
