//
//  SummaryStep.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct SummaryStep: View {
    @ObservedObject var viewModel: InteractiveIntroductionViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ResponsivePadding.large) {
                // Header
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("Onboarding.Summary.Title", comment: "Summary title"))
                        .font(.title2Responsive)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("Onboarding.Summary.Description", comment: "Summary description"))
                        .font(.bodyResponsive)
                        .foregroundStyle(.secondary)
                }
                
                // Summary Cards
                VStack(spacing: ResponsivePadding.medium) {
                    SummaryCard(
                        title: NSLocalizedString("Onboarding.Summary.BasicInfo", comment: "Basic info summary"),
                        content: "\(viewModel.userModel.fullName), \(viewModel.selectedGender), \(viewModel.selectedAge) " + NSLocalizedString("Onboarding.Summary.AgeUnit", comment: "Age unit")
                    )
                    
                    if !viewModel.selectedChronicDiseases.isEmpty || !viewModel.selectedAllergies.isEmpty {
                        SummaryCard(
                            title: NSLocalizedString("Onboarding.Summary.HealthInfo", comment: "Health info summary"),
                            content: """
                            \(NSLocalizedString("Onboarding.Summary.ChronicDiseases", comment: "")): \(viewModel.selectedChronicDiseases.isEmpty ? NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.None", comment: "") : viewModel.selectedChronicDiseases.joined(separator: ", "))
                            \(NSLocalizedString("Onboarding.Summary.Allergies", comment: "")): \(viewModel.selectedAllergies.isEmpty ? NSLocalizedString("Onboarding.HealthInfo.Allergies.None", comment: "") : viewModel.selectedAllergies.joined(separator: ", "))
                            """
                        )
                    }
                    
                    SummaryCard(
                        title: NSLocalizedString("Onboarding.Summary.Lifestyle", comment: "Lifestyle summary"),
                        content: """
                        \(NSLocalizedString("Onboarding.Summary.Sleep", comment: "")): \(viewModel.selectedSleepPattern)
                        \(NSLocalizedString("Onboarding.Summary.Activity", comment: "")): \(viewModel.selectedPhysicalActivity)
                        \(NSLocalizedString("Onboarding.Summary.Nutrition", comment: "")): \(viewModel.selectedNutritionHabits)
                        """
                    )
                }
                
                // Disclaimer
                VStack(alignment: .leading, spacing: ResponsivePadding.xSmall) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(NSLocalizedString("Onboarding.Summary.Disclaimer", comment: "Legal/medical disclaimer"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(ResponsivePadding.medium)
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                            .fill(Color.orange.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                Spacer(minLength: ResponsivePadding.extraLarge)
            }
            .padding(.horizontal, ResponsivePadding.large)
        }
    }
}
