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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                    // Title & Subtitle
                    VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                        Text(NSLocalizedString("DepartmentSuggestion.Title", comment: ""))
                            .font(.title1Responsive)
                            .fontWeight(.bold)
                        Text(NSLocalizedString("DepartmentSuggestion.Subtitle", comment: ""))
                            .font(.subheadlineResponsive)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.top, ResponsivePadding.medium)

                    // Symptoms chips grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: UIScreen.screenWidth / 2 - ResponsivePadding.extraLarge))], spacing: ResponsivePadding.small) {
                        ForEach(viewModel.predefinedSymptoms, id: \.self) { symptom in
                            SelectionButton(title: symptom, isSelected: viewModel.selectedSymptoms.contains(symptom)) {
                                viewModel.toggleSymptom(symptom)
                            }
                        }
                        // Other toggle
                        SelectionButton(title: NSLocalizedString("DepartmentSuggestion.Other", comment: ""), isSelected: viewModel.includeOther) {
                            withAnimation { viewModel.includeOther.toggle(); isOtherExpanded = viewModel.includeOther }
                        }
                    }
                    .padding(.horizontal, ResponsivePadding.large)

                    if viewModel.includeOther {
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
                        HStack { ProgressView(); Text(NSLocalizedString("Common.Loading", comment: "")) }
                            .padding(.horizontal, ResponsivePadding.large)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding(.horizontal, ResponsivePadding.large)
                    } else if !viewModel.results.isEmpty {
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            ForEach(viewModel.results) { item in
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
                                    
                                    // Progress bar
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
                            
                            // Save button
                            if !viewModel.results.isEmpty {
                                Button(action: saveToHistory) {
                                    HStack {
                                        if viewModel.isSaving {
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
                                .disabled(viewModel.isSaving)
                                
                                if let saveMsg = viewModel.saveMessage {
                                    Text(saveMsg)
                                        .font(.captionResponsive)
                                        .foregroundStyle(saveMsg.contains("başarı") ? .green : .red)
                                        .padding(.top, ResponsivePadding.small)
                                }
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

#Preview {
    DepartmentSuggestionView()
}
