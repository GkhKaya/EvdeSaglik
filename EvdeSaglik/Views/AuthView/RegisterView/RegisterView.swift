import SwiftUI
import FirebaseAuth

// MARK: - String Extension for Identifiable
extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct RegisterView: View {
    @StateObject private var viewModel: RegisterViewViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool
    
    init(authManager: FirebaseAuthManager) {
        _viewModel = StateObject(wrappedValue: RegisterViewViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ResponsivePadding.large) {
                    // Header
                    VStack(spacing: ResponsivePadding.medium) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text(NSLocalizedString("Register.Title", comment: "Create Account"))
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("Register.Subtitle", comment: "Join us today"))
                            .font(.subheadlineResponsive)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, ResponsivePadding.large)
                    
                    // Form
                    VStack(spacing: ResponsivePadding.large) {
                        // Email Field
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            Text(NSLocalizedString("Register.Email", comment: "Email"))
                                .font(.headlineResponsive)
                                .fontWeight(.medium)
                            
                            CustomTextField(
                                title: "",
                                placeholder: NSLocalizedString("Register.EmailPlaceholder", comment: "Enter your email"),
                                icon: "envelope",
                                text: $viewModel.email,
                                isMultiline: false
                            )
                            .focused($isEmailFocused)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            
                            // Email validation message
                            if !viewModel.emailValidationMessage.isEmpty {
                                Text(viewModel.emailValidationMessage)
                                    .font(.captionResponsive)
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            Text(NSLocalizedString("Register.Password", comment: "Password"))
                                .font(.headlineResponsive)
                                .fontWeight(.medium)
                            
                            CustomTextField(
                                title: "",
                                placeholder: NSLocalizedString("Register.PasswordPlaceholder", comment: "Enter your password"),
                                icon: "key",
                                text: $viewModel.password,
                                isSecure: true,
                                showPasswordToggle: true,
                                isMultiline: false
                            )
                            .focused($isPasswordFocused)
                            .textContentType(.newPassword)
                            
                            // Password validation message
                            if !viewModel.passwordValidationMessage.isEmpty {
                                Text(viewModel.passwordValidationMessage)
                                    .font(.captionResponsive)
                                    .foregroundStyle(.red)
                            }
                            
                            // Password strength indicator
                            if !viewModel.password.isEmpty {
                                PasswordStrengthView(strength: viewModel.passwordStrength)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            Text(NSLocalizedString("Register.ConfirmPassword", comment: "Confirm Password"))
                                .font(.headlineResponsive)
                                .fontWeight(.medium)
                            
                            CustomTextField(
                                title: "",
                                placeholder: NSLocalizedString("Register.ConfirmPasswordPlaceholder", comment: "Confirm your password"),
                                icon: "key.fill",
                                text: $viewModel.confirmPassword,
                                isSecure: true,
                                showPasswordToggle: true,
                                isMultiline: false
                            )
                            .focused($isConfirmPasswordFocused)
                            .textContentType(.newPassword)
                        }
                        
                        // Error message
                        errorMessage
                        
                        // Register Button
                        registerButton
                        
                        // Login Link
                        HStack {
                            Text(NSLocalizedString("Register.AlreadyHaveAccount", comment: "Already have an account?"))
                                .font(.bodyResponsive)
                                .foregroundStyle(.secondary)
                            
                            NavigationLink(destination: LoginView()) {
                                Text(NSLocalizedString("Register.SignIn", comment: "Sign In"))
                                    .font(.bodyResponsive)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.top, ResponsivePadding.medium)
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    
                    Spacer(minLength: ResponsivePadding.large)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle(NSLocalizedString("Register.Title", comment: "Create Account"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(item: $viewModel.errorMessage) { error in
                Alert(
                    title: Text(NSLocalizedString("Error", comment: "")),
                    message: Text(error),
                    dismissButton: .default(Text(NSLocalizedString("OK", comment: "")))
                )
            }
            .alert(item: $viewModel.successMessage) { message in
                Alert(
                    title: Text(NSLocalizedString("Success", comment: "")),
                    message: Text(message),
                    dismissButton: .default(Text(NSLocalizedString("OK", comment: "")))
                )
            }
        }
    }
    
    // MARK: - Computed Views
    
    /// Error message display
    var errorMessage: some View {
        Group {
            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, ResponsivePadding.small)
            }
        }
    }
    
    /// Register button
    var registerButton: some View {
        CustomButton(
            title: NSLocalizedString("Register.Register", comment: "Register"),
            action: {
                viewModel.register(authManager: authManager)
            },
            isEnabled: viewModel.isFormValid,
            isLoading: viewModel.isLoading
        )
    }
}

// MARK: - Password Strength View

struct PasswordStrengthView: View {
    let strength: PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            HStack {
                Text(NSLocalizedString("Register.PasswordStrength", comment: "Password Strength"))
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(strengthText)
                    .font(.captionResponsive)
                    .fontWeight(.medium)
                    .foregroundStyle(strengthColor)
            }
            
            // Strength indicator
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index < strengthLevel ? strengthColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
        }
    }
    
    private var strengthLevel: Int {
        switch strength {
        case .none: return 0
        case .weak: return 1
        case .medium: return 2
        case .strong: return 3
        case .veryStrong: return 4
        }
    }
    
    private var strengthText: String {
        switch strength {
        case .none: return NSLocalizedString("Register.PasswordStrength.None", comment: "None")
        case .weak: return NSLocalizedString("Register.PasswordStrength.Weak", comment: "Weak")
        case .medium: return NSLocalizedString("Register.PasswordStrength.Medium", comment: "Medium")
        case .strong: return NSLocalizedString("Register.PasswordStrength.Strong", comment: "Strong")
        case .veryStrong: return NSLocalizedString("Register.PasswordStrength.VeryStrong", comment: "Very Strong")
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case .none: return .gray
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .yellow
        case .veryStrong: return .green
        }
    }
}


#Preview {
    RegisterView(authManager: FirebaseAuthManager())
        .environmentObject(FirebaseAuthManager())
        .environmentObject(FirestoreManager())
}