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
    
    // History view states
    @State private var showingDepartmentSuggestionHistory = false
    @State private var showingDiseasePredictionHistory = false
    @State private var showingHomeSolutionHistory = false
    @State private var showingLabResultHistory = false
    @State private var showingNaturalSolutionHistory = false
    @State private var showingDrugFoodInteractionHistory = false
    
    init(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(authManager: authManager, firestoreManager: firestoreManager))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ResponsivePadding.large) {
                    // Header
                    ProfileHeader(
                        userName: viewModel.currentUserName,
                        userEmail: viewModel.currentUserEmail
                    )
                    
                    // Saved Data Sections
                    SavedDataSections(
                        showingDepartmentSuggestionHistory: $showingDepartmentSuggestionHistory,
                        showingDiseasePredictionHistory: $showingDiseasePredictionHistory,
                        showingHomeSolutionHistory: $showingHomeSolutionHistory,
                        showingLabResultHistory: $showingLabResultHistory,
                        showingNaturalSolutionHistory: $showingNaturalSolutionHistory,
                        showingDrugFoodInteractionHistory: $showingDrugFoodInteractionHistory
                    )
                    
                    // Account Settings Section
                    AccountSettingsSection(viewModel: viewModel)
                    
                    // Danger Zone Section
                    DangerZoneSection(viewModel: viewModel)
                }
                .padding(.horizontal, ResponsivePadding.large)
            }
            .navigationTitle(NSLocalizedString("Profile.Title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingPersonalization) {
                InteractiveIntroductionView(
                    firestoreManager: firestoreManager,
                    authManager: authManager
                )
            }
            .sheet(isPresented: $viewModel.showingChangeEmail) {
                ChangeEmailView(authManager: authManager)
            }
            .sheet(isPresented: $viewModel.showingChangePassword) {
                ChangePasswordView(authManager: authManager)
            }
                .sheet(isPresented: $showingDepartmentSuggestionHistory) {
                    DepartmentSuggestionHistoryView(firestoreManager: firestoreManager, authManager: authManager)
                }
                .sheet(isPresented: $showingDiseasePredictionHistory) {
                    DiseasePredictionHistoryView(firestoreManager: firestoreManager, authManager: authManager)
                }
                .sheet(isPresented: $showingHomeSolutionHistory) {
                    HomeSolutionHistoryView(firestoreManager: firestoreManager, authManager: authManager)
                }
                .sheet(isPresented: $showingLabResultHistory) {
                    LabResultRecommendationHistoryView(firestoreManager: firestoreManager, authManager: authManager)
                }
                .sheet(isPresented: $showingNaturalSolutionHistory) {
                    NaturalSolutionHistoryView(firestoreManager: firestoreManager, authManager: authManager)
                }
                .sheet(isPresented: $showingDrugFoodInteractionHistory) {
                    DrugFoodInteractionHistoryView(firestoreManager: firestoreManager, authManager: authManager)
                }
            .alert(NSLocalizedString("Profile.Alert.DeleteAccount", comment: ""), isPresented: $viewModel.showingDeleteAccount) {
                Button(NSLocalizedString("Profile.Alert.Cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("Profile.Alert.Delete", comment: ""), role: .destructive) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
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
    @Binding var showingDepartmentSuggestionHistory: Bool
    @Binding var showingDiseasePredictionHistory: Bool
    @Binding var showingHomeSolutionHistory: Bool
    @Binding var showingLabResultHistory: Bool
    @Binding var showingNaturalSolutionHistory: Bool
    @Binding var showingDrugFoodInteractionHistory: Bool
    
    var body: some View {
        VStack(spacing: ResponsivePadding.medium) {
            DepartmentSuggestionsSection(
                showingDepartmentSuggestionHistory: $showingDepartmentSuggestionHistory
            )
            DiseasePredictionsSection(
                showingDiseasePredictionHistory: $showingDiseasePredictionHistory
            )
            HomeSolutionsSection(
                showingHomeSolutionHistory: $showingHomeSolutionHistory
            )
            LabResultsSection(
                showingLabResultHistory: $showingLabResultHistory
            )
            NaturalSolutionsSection(
                showingNaturalSolutionHistory: $showingNaturalSolutionHistory
            )
            DrugFoodInteractionSection(
                showingDrugFoodInteractionHistory: $showingDrugFoodInteractionHistory
            )
        }
    }
}


