//
//  NaturalSolitionsView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct NaturalSolitionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @StateObject private var viewModel = NaturalSolutionsViewViewModel()
    @State private var isOtherExpanded: Bool = false
    @FocusState private var isOtherFocused: Bool
    @FocusState private var isFeelingsFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                    // Header
                    VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                        Text(NSLocalizedString("NaturalSolutions.Title", comment: ""))
                            .font(.title1Responsive)
                            .fontWeight(.bold)
                        Text(NSLocalizedString("NaturalSolutions.Subtitle", comment: ""))
                            .font(.subheadlineResponsive)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.top, ResponsivePadding.medium)
                    
                    // Concerns chips grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: UIScreen.screenWidth / 2 - ResponsivePadding.extraLarge))], spacing: ResponsivePadding.small) {
                        ForEach(viewModel.predefinedConcerns, id: \.self) { concern in
                            SelectionButton(title: concern, isSelected: viewModel.selectedConcerns.contains(concern)) {
                                viewModel.toggleConcern(concern)
                            }
                        }
                        // Other toggle
                        SelectionButton(title: NSLocalizedString("NaturalSolutions.Other", comment: ""), isSelected: viewModel.includeOther) {
                            withAnimation { viewModel.includeOther.toggle(); isOtherExpanded = viewModel.includeOther }
                        }
                    }
                    .padding(.horizontal, ResponsivePadding.large)

                    if viewModel.includeOther {
                        CustomTextField(
                            title: NSLocalizedString("NaturalSolutions.OtherTitle", comment: ""),
                            placeholder: NSLocalizedString("NaturalSolutions.OtherPlaceholder", comment: ""),
                            icon: "text.bubble",
                            text: $viewModel.otherConcernsText,
                            isMultiline: true
                        )
                        .focused($isOtherFocused)
                        .padding(.horizontal, ResponsivePadding.large)
                    }

                    // Feelings input single-line
                    CustomTextField(
                        title: NSLocalizedString("NaturalSolutions.FeelingsTitle", comment: ""),
                        placeholder: NSLocalizedString("NaturalSolutions.FeelingsPlaceholder", comment: ""),
                        icon: "person.text.rectangle",
                        text: $viewModel.feelingsText,
                        isMultiline: false
                    )
                    .focused($isFeelingsFocused)
                    .padding(.horizontal, ResponsivePadding.large)
                    
                    // Results
                    if viewModel.isLoading {
                        HStack { 
                            ProgressView()
                            Text(NSLocalizedString("Common.Loading", comment: ""))
                        }
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
                                    Text(NSLocalizedString("NaturalSolutions.Save", comment: ""))
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
                        Text(NSLocalizedString("NaturalSolutions.Submit", comment: ""))
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
                .disabled(viewModel.isLoading)
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
        Task { await viewModel.requestNaturalSolutions(userSummary: summary) }
    }
    
    private func saveToHistory() {
        if let userId = userManager.authManager?.currentUser?.uid {
            Task { viewModel.saveNaturalSolutions(userId: userId, firestoreManager: userManager.firestoreManager) }
        }
    }
}

#Preview {
    NaturalSolitionsView()
}
