//
//  WelcomeStep.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct WelcomeStep: View {
    @ObservedObject var viewModel: InteractiveIntroductionViewModel
    
    var body: some View {
        VStack(spacing: ResponsivePadding.large) {
            // Icon
            Image(systemName: "hand.wave.fill")
                .font(.largeTitleResponsive)
                .foregroundStyle(.blue)
            
            // Content
            VStack(spacing: ResponsivePadding.medium) {
                Text(String(format: NSLocalizedString("Onboarding.Welcome.Title", comment: "Welcome title"), viewModel.userModel.fullName))
                    .font(.title1Responsive)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("Onboarding.Welcome.Description", comment: "Welcome description"))
                    .font(.bodyResponsive)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, ResponsivePadding.large)
    }
}
