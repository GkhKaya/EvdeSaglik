//
//  IntroductionStep.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct IntroductionStep: View {
    @ObservedObject var viewModel: InteractiveIntroductionViewModel
    
    var body: some View {
        VStack(spacing: ResponsivePadding.large) {
            // Icon
            Image(systemName: "heart.text.square.fill")
                .font(.largeTitleResponsive)
                .foregroundStyle(.blue)
            
            // Content
            VStack(spacing: ResponsivePadding.medium) {
                Text(NSLocalizedString("Onboarding.Intro.Title", comment: "Introduction title"))
                    .font(.title1Responsive)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("Onboarding.Intro.Description", comment: "Introduction description"))
                    .font(.bodyResponsive)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: ResponsivePadding.medium) {
                CustomButton(
                    title: NSLocalizedString("Onboarding.Skip", comment: "Skip button"),
                    action: viewModel.skipOnboarding,
                    style: .secondary,
                    innerPadding: ResponsivePadding.small
                )
                .frame(maxWidth: .infinity)
                
                CustomButton(
                    title: NSLocalizedString("Onboarding.Next", comment: "Next button"),
                    action: viewModel.nextStep,
                    innerPadding: ResponsivePadding.small
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, ResponsivePadding.large)
    }
}
