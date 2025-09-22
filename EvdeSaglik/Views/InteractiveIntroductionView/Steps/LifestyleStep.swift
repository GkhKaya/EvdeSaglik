//
//  LifestyleStep.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct LifestyleStep: View {
    @ObservedObject var viewModel: InteractiveIntroductionViewModel
    
    private let sleepOptions = [
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Sleep.Good", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Sleep.GoodDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Sleep.GoodExample", comment: "")
        ),
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Sleep.Medium", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Sleep.MediumDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Sleep.MediumExample", comment: "")
        ),
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Sleep.Bad", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Sleep.BadDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Sleep.BadExample", comment: "")
        )
    ]
    
    private let activityOptions = [
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Activity.Low", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Activity.LowDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Activity.LowExample", comment: "")
        ),
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Activity.Medium", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Activity.MediumDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Activity.MediumExample", comment: "")
        ),
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Activity.High", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Activity.HighDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Activity.HighExample", comment: "")
        )
    ]
    
    private let nutritionOptions = [
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Nutrition.Bad", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Nutrition.BadDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Nutrition.BadExample", comment: "")
        ),
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Nutrition.Medium", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Nutrition.MediumDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Nutrition.MediumExample", comment: "")
        ),
        LifestyleOption(
            title: NSLocalizedString("Onboarding.Lifestyle.Nutrition.Good", comment: ""),
            description: NSLocalizedString("Onboarding.Lifestyle.Nutrition.GoodDescription", comment: ""),
            example: NSLocalizedString("Onboarding.Lifestyle.Nutrition.GoodExample", comment: "")
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ResponsivePadding.large) {
                // Header
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("Onboarding.Lifestyle.Title", comment: "Lifestyle title"))
                        .font(.title2Responsive)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("Onboarding.Lifestyle.Description", comment: "Lifestyle description"))
                        .font(.bodyResponsive)
                        .foregroundStyle(.secondary)
                }
                
                // Sleep Pattern
                LifestyleSelectionView(
                    title: NSLocalizedString("Onboarding.Lifestyle.Sleep", comment: "Sleep pattern"),
                    description: NSLocalizedString("Onboarding.Lifestyle.SleepDescription", comment: "Sleep description"),
                    options: sleepOptions,
                    selectedOption: $viewModel.selectedSleepPattern
                )
                
                // Physical Activity
                LifestyleSelectionView(
                    title: NSLocalizedString("Onboarding.Lifestyle.Activity", comment: "Physical activity"),
                    description: NSLocalizedString("Onboarding.Lifestyle.ActivityDescription", comment: "Activity description"),
                    options: activityOptions,
                    selectedOption: $viewModel.selectedPhysicalActivity
                )
                
                // Nutrition Habits
                LifestyleSelectionView(
                    title: NSLocalizedString("Onboarding.Lifestyle.Nutrition", comment: "Nutrition habits"),
                    description: NSLocalizedString("Onboarding.Lifestyle.NutritionDescription", comment: "Nutrition description"),
                    options: nutritionOptions,
                    selectedOption: $viewModel.selectedNutritionHabits
                )
                
                Spacer(minLength: ResponsivePadding.extraLarge)
            }
            .padding(.horizontal, ResponsivePadding.large)
        }
    }
}
