//
//  DepartmentSuggestionView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct DepartmentSuggestionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @StateObject private var viewModel = DepartmentSuggestionViewViewModel()
    @State private var isOtherExpanded: Bool = false
    @FocusState private var isOtherFocused: Bool
    @State private var isSubmitting: Bool = false
    
    // Hoist complex grid configuration to avoid heavy inline expressions
    private let gridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: UIScreen.screenWidth / 2 - ResponsivePadding.extraLarge))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                    TitleSection()
                        .padding(.horizontal, ResponsivePadding.large)
                        .padding(.top, ResponsivePadding.medium)

                    // Symptoms chips grid
                    LazyVGrid(columns: gridColumns, spacing: ResponsivePadding.small) {
                        ForEach(viewModel.predefinedSymptoms, id: \.self) { symptom in
                            SelectionButton(title: symptom, isSelected: viewModel.selectedSymptoms.contains(symptom)) {
                                viewModel.toggleSymptom(symptom)
                            }
                        }
                        // Other toggle
                        SelectionButton(
                            title: NSLocalizedString("DepartmentSuggestion.Other", comment: ""),
                            isSelected: viewModel.includeOther
                        ) {
                            withAnimation {
                                viewModel.includeOther.toggle()
                            }
                            isOtherExpanded = viewModel.includeOther
                        }
                    }
                    .padding(.horizontal, ResponsivePadding.large)

                    if viewModel.includeOther {
                        otherSymptomsField
                    }

                    // Feelings input single-line
                    CustomTextField(
                        title: NSLocalizedString("DepartmentSuggestion.FeelingsTitle", comment: ""),
                        placeholder: NSLocalizedString("DepartmentSuggestion.FeelingsPlaceholder", comment: ""),
                        icon: "person.text.rectangle",
                        text: $viewModel.feelingsText,
                        isMultiline: false
                    )
                    .padding(.horizontal, ResponsivePadding.large)

                    // Results section
                    if viewModel.isLoading {
                        StandardLoadingView(message: NSLocalizedString("Common.Loading", comment: ""))
                            .frame(height: 100)
                    } else if !viewModel.results.isEmpty {
                        DepartmentResultsSection(
                            results: viewModel.results,
                            isSaving: viewModel.isSaving,
                            onSave: saveToHistory
                        )
                        .padding(.horizontal, ResponsivePadding.large)
                    }

                    Spacer(minLength: ResponsivePadding.large)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: submit) {
                    HStack {
                        if viewModel.isLoading { ProgressView() }
                        Text(NSLocalizedString("DepartmentSuggestion.Submit", comment: ""))
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
        .messageDisplay(for: viewModel)
        .alert(NSLocalizedString("DepartmentSuggestion.SaveSuccess", comment: ""), isPresented: $viewModel.showSuccessAlert) {
            Button(NSLocalizedString("Common.OK", comment: "")) {
                viewModel.showSuccessAlert = false
            }
        } message: {
            Text(NSLocalizedString("DepartmentSuggestion.SaveSuccessMessage", comment: ""))
        }
    }
    
    private func submit() {
        let summary = userManager.generateUserSummaryPrompt()
        Task { await viewModel.requestSuggestions(userSummary: summary) }
    }
    
    private func saveToHistory() {
        if let userId = userManager.authManager?.currentUser?.uid {
            Task { await viewModel.saveSuggestions(userId: userId, firestoreManager: userManager.firestoreManager) }
        }
    }
}

// MARK: - Subviews to simplify type-checking
private extension DepartmentSuggestionView {
    struct TitleSection: View {
        var body: some View {
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("DepartmentSuggestion.Title", comment: ""))
                    .font(.title1Responsive)
                    .fontWeight(.bold)
                Text(NSLocalizedString("DepartmentSuggestion.Subtitle", comment: ""))
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var otherSymptomsField: some View {
        CustomTextField(
            title: NSLocalizedString("DepartmentSuggestion.OtherTitle", comment: ""),
            placeholder: NSLocalizedString("DepartmentSuggestion.OtherPlaceholder", comment: ""),
            icon: "text.bubble",
            text: $viewModel.otherSymptomsText,
            isMultiline: true
        )
        .focused($isOtherFocused)
        .padding(.horizontal, ResponsivePadding.large)
    }
}

struct DepartmentResultsSection: View {
    let results: [DepartmentSuggestionResult]
    let isSaving: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            ForEach(results) { item in
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    HStack {
                        VStack(alignment: .leading, spacing: ResponsivePadding.xSmall) {
                            Text(item.name)
                                .font(.headlineResponsive)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(String(format: NSLocalizedString("DepartmentSuggestion.Confidence", comment: ""), Int(item.confidence)))
                                .font(.captionResponsive)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(item.confidence))%")
                            .font(.title2Responsive)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                                .fill(Color.accentColor)
                                .frame(width: geometry.size.width * CGFloat(item.confidence/100.0), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(ResponsivePadding.medium)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color(.systemGray).opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            
            Button(action: onSave) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text(NSLocalizedString("DepartmentSuggestion.Save", comment: ""))
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
            .disabled(isSaving)
            
            // Success/Failure message is shown via BaseViewModel in the parent view
        }
    }
}

#Preview {
    DepartmentSuggestionView()
}
