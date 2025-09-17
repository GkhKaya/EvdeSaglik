//
//  HomeSolutionView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct HomeSolutionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @StateObject private var viewModel = HomeSolutionViewViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                    // Header
                    VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                        Text(NSLocalizedString("HomeSolution.Title", comment: ""))
                            .font(.title1Responsive)
                            .fontWeight(.bold)
                        Text(NSLocalizedString("HomeSolution.Subtitle", comment: ""))
                            .font(.subheadlineResponsive)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.top, ResponsivePadding.medium)

                    // Input
                    CustomTextField(
                        title: NSLocalizedString("HomeSolution.InputTitle", comment: ""),
                        placeholder: NSLocalizedString("HomeSolution.InputPlaceholder", comment: ""),
                        icon: "text.bubble",
                        text: $viewModel.inputText,
                        isMultiline: false
                    )
                    .focused($isFocused)
                    .padding(.horizontal, ResponsivePadding.large)

                    // Result
                    if viewModel.isLoading {
                        HStack { ProgressView(); Text(NSLocalizedString("Common.Loading", comment: "")) }
                            .padding(.horizontal, ResponsivePadding.large)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding(.horizontal, ResponsivePadding.large)
                    } else if !viewModel.resultText.isEmpty {
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            Text(viewModel.resultText)
                                .font(.bodyResponsive)
                                .foregroundStyle(.primary)
                                .padding(ResponsivePadding.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color(.systemGray).opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                            
                            // Save button
                            Button(action: saveToHistory) {
                                HStack {
                                    if viewModel.isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                    }
                                    Text(NSLocalizedString("HomeSolution.Save", comment: ""))
                                        .font(.bodyResponsive)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(ResponsivePadding.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                        .fill(Color(.systemGray6))
                                )
                                .foregroundStyle(.primary)
                            }
                            .disabled(viewModel.isSaving)
                            
                            if let saveMsg = viewModel.saveMessage {
                                Text(saveMsg)
                                    .font(.captionResponsive)
                                    .foregroundStyle(saveMsg.contains("başarı") ? .green : .red)
                                    .padding(.top, ResponsivePadding.small)
                            }
                        }
                        .padding(.horizontal, ResponsivePadding.large)
                    }

                    Spacer(minLength: ResponsivePadding.large)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: submit) {
                    HStack {
                        if viewModel.isLoading { ProgressView() }
                        Text(NSLocalizedString("HomeSolution.Submit", comment: ""))
                            .font(.bodyResponsive)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(ResponsivePadding.medium)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.vertical, ResponsivePadding.medium)
                }
                .disabled(viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.bodyResponsive)
                    }
                }
            }
        }
    }

    private func submit() {
        let summary = userManager.generateUserSummaryPrompt()
        Task { await viewModel.requestHomeSolutions(userSummary: summary) }
    }
    
    private func saveToHistory() {
        if let userId = userManager.authManager?.currentUser?.uid {
            Task { await viewModel.saveSolution(userId: userId, firestoreManager: userManager.firestoreManager) }
        }
    }
}

#Preview {
    HomeSolutionView()
}
