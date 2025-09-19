//
//  ProfileView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @StateObject private var viewModel: ProfileViewModel
    
    init(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(authManager: authManager, firestoreManager: firestoreManager))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ResponsivePadding.large) {
                    // Header
                    VStack(spacing: ResponsivePadding.medium) {
                        // Profile Avatar
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)
                        
                        // User Info
                        VStack(spacing: ResponsivePadding.small) {
                            Text(viewModel.currentUserName.isEmpty ? NSLocalizedString("Profile.UserName", comment: "") : viewModel.currentUserName)
                                .font(.title2Responsive)
                                .fontWeight(.semibold)
                            
                            Text(viewModel.currentUserEmail)
                                .font(.subheadlineResponsive)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, ResponsivePadding.large)
                    
                    // Account Information Section
                    ProfileSection(
                        title: NSLocalizedString("Profile.Section.AccountInfo", comment: ""),
                        items: [
                            ProfileItem(
                                title: NSLocalizedString("Profile.Item.Email", comment: ""),
                                value: viewModel.currentUserEmail,
                                icon: "envelope",
                                action: { viewModel.showingChangeEmail = true }
                            ),
                            ProfileItem(
                                title: NSLocalizedString("Profile.Item.Password", comment: ""),
                                value: NSLocalizedString("Profile.Item.PasswordValue", comment: ""),
                                icon: "key",
                                action: { viewModel.showingChangePassword = true }
                            )
                        ]
                    )
                    
                    // Personalization Section
                    ProfileSection(
                        title: NSLocalizedString("Profile.Section.Personalization", comment: ""),
                        items: [
                            ProfileItem(
                                title: NSLocalizedString("Profile.Item.Personalize", comment: ""),
                                value: NSLocalizedString("Profile.Item.PersonalizeValue", comment: ""),
                                icon: "person.text.rectangle",
                                action: { viewModel.showingPersonalization = true }
                            )
                        ]
                    )
                    
                    // Saved Data Sections
                    SavedDataSections(viewModel: viewModel)
                    
                    // Account Settings Section
                    ProfileSection(
                        title: NSLocalizedString("Profile.Section.AccountSettings", comment: ""),
                        items: [
                            ProfileItem(
                                title: NSLocalizedString("Profile.Item.ResetData", comment: ""),
                                value: NSLocalizedString("Profile.Item.ResetDataValue", comment: ""),
                                icon: "arrow.clockwise",
                                action: { viewModel.showingResetData = true },
                                isDestructive: true
                            ),
                            ProfileItem(
                                title: NSLocalizedString("Profile.Item.DeleteAccount", comment: ""),
                                value: NSLocalizedString("Profile.Item.DeleteAccountValue", comment: ""),
                                icon: "trash",
                                action: { viewModel.showingDeleteAccount = true },
                                isDestructive: true
                            )
                        ]
                    )
                    
                    Spacer(minLength: ResponsivePadding.extraLarge)
                }
                .padding(.horizontal, ResponsivePadding.large)
            }
            .navigationTitle(NSLocalizedString("Profile.Title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.bodyResponsive)
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
            .sheet(isPresented: $viewModel.showingPersonalization) {
                InteractiveIntroductionView(
                    firestoreManager: firestoreManager,
                    authManager: authManager
                )
            }
            .sheet(isPresented: $viewModel.showingChangeEmail) {
                ChangeEmailView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingChangePassword) {
                ChangePasswordView(viewModel: viewModel)
            }
            .alert(NSLocalizedString("Profile.Alert.ResetData", comment: ""), isPresented: $viewModel.showingResetData) {
                Button(NSLocalizedString("Profile.Action.Cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("Profile.Action.Reset", comment: ""), role: .destructive) {
                    Task { await viewModel.resetUserData() }
                }
            } message: {
                Text(NSLocalizedString("Profile.Alert.ResetDataMessage", comment: ""))
            }
            .alert(NSLocalizedString("Profile.Alert.DeleteAccount", comment: ""), isPresented: $viewModel.showingDeleteAccount) {
                Button(NSLocalizedString("Profile.Action.Cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("Profile.Action.Delete", comment: ""), role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
            } message: {
                Text(NSLocalizedString("Profile.Alert.DeleteAccountMessage", comment: ""))
            }
        }
    }
}

// MARK: - Profile Section
struct ProfileSection: View {
    let title: String
    let items: [ProfileItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            Text(title)
                .font(.headlineResponsive)
                .fontWeight(.semibold)
                .padding(.horizontal, ResponsivePadding.small)
            
            VStack(spacing: 1) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ProfileItemView(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.horizontal, ResponsivePadding.medium)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.systemGray).opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Profile Item
struct ProfileItem {
    let title: String
    let value: String
    let icon: String
    let action: () -> Void
    var isDestructive: Bool = false
    var isSelected: Bool = false
}

struct ProfileItemView: View {
    let item: ProfileItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: ResponsivePadding.medium) {
                Image(systemName: item.icon)
                    .font(.bodyResponsive)
                    .foregroundStyle(item.isDestructive ? .red : .blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.bodyResponsive)
                        .fontWeight(.medium)
                        .foregroundStyle(item.isDestructive ? .red : .primary)
                    
                    Text(item.value)
                        .font(.captionResponsive)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
            }
            .padding(ResponsivePadding.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Rectangle()
                .fill(Color.blue)
                .frame(height: item.isSelected ? 2 : 0),
            alignment: .bottom
        )
    }
}

// MARK: - Saved Data Sections
struct SavedDataSections: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: ResponsivePadding.medium) {
            // Department Suggestions
            ProfileSection(
                title: NSLocalizedString("Profile.Section.DepartmentSuggestions", comment: ""),
                items: [
                    ProfileItem(
                        title: NSLocalizedString("Profile.Item.ViewHistory", comment: ""),
                        value: NSLocalizedString("Profile.Item.ViewHistoryValue", comment: ""),
                        icon: "list.bullet",
                        action: { 
                            viewModel.selectCategory("departmentSuggestions")
                            // TODO: Navigate to history 
                        },
                        isSelected: viewModel.isCategorySelected("departmentSuggestions")
                    )
                ]
            )
            
            // Disease Predictions
            ProfileSection(
                title: NSLocalizedString("Profile.Section.DiseasePredictions", comment: ""),
                items: [
                    ProfileItem(
                        title: NSLocalizedString("Profile.Item.ViewHistory", comment: ""),
                        value: NSLocalizedString("Profile.Item.ViewHistoryValue", comment: ""),
                        icon: "list.bullet",
                        action: { 
                            viewModel.selectCategory("diseasePredictions")
                            // TODO: Navigate to history 
                        },
                        isSelected: viewModel.isCategorySelected("diseasePredictions")
                    )
                ]
            )
            
            // Home Solutions
            ProfileSection(
                title: NSLocalizedString("Profile.Section.HomeSolutions", comment: ""),
                items: [
                    ProfileItem(
                        title: NSLocalizedString("Profile.Item.ViewHistory", comment: ""),
                        value: NSLocalizedString("Profile.Item.ViewHistoryValue", comment: ""),
                        icon: "list.bullet",
                        action: { 
                            viewModel.selectCategory("homeSolutions")
                            // TODO: Navigate to history 
                        },
                        isSelected: viewModel.isCategorySelected("homeSolutions")
                    )
                ]
            )
            
            // Lab Results
            ProfileSection(
                title: NSLocalizedString("Profile.Section.LabResults", comment: ""),
                items: [
                    ProfileItem(
                        title: NSLocalizedString("Profile.Item.ViewHistory", comment: ""),
                        value: NSLocalizedString("Profile.Item.ViewHistoryValue", comment: ""),
                        icon: "list.bullet",
                        action: { 
                            viewModel.selectCategory("labResults")
                            // TODO: Navigate to history 
                        },
                        isSelected: viewModel.isCategorySelected("labResults")
                    )
                ]
            )
            
            // Natural Solutions
            ProfileSection(
                title: NSLocalizedString("Profile.Section.NaturalSolutions", comment: ""),
                items: [
                    ProfileItem(
                        title: NSLocalizedString("Profile.Item.ViewHistory", comment: ""),
                        value: NSLocalizedString("Profile.Item.ViewHistoryValue", comment: ""),
                        icon: "list.bullet",
                        action: { 
                            viewModel.selectCategory("naturalSolutions")
                            // TODO: Navigate to history 
                        },
                        isSelected: viewModel.isCategorySelected("naturalSolutions")
                    )
                ]
            )
        }
    }
}

// MARK: - Change Email View
struct ChangeEmailView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool
    
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
        }
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCurrentPasswordFocused: Bool
    @FocusState private var isNewPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool
    
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
        }
    }
}
