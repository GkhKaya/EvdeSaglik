//
//  InteractiveIntroductionView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct InteractiveIntroductionView: View {
    // MARK: - Properties
    @ObservedObject private var viewModel: InteractiveIntroductionViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var authManager: FirebaseAuthManager
    
    let onOnboardingComplete: (() -> Void)?
    let isFromProfile: Bool
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager, onOnboardingComplete: (() -> Void)? = nil, isFromProfile: Bool = false) {
        self.onOnboardingComplete = onOnboardingComplete
        self.isFromProfile = isFromProfile
        _viewModel = ObservedObject(wrappedValue: InteractiveIntroductionViewModel(firestoreManager: firestoreManager, authManager: authManager, isFromProfile: isFromProfile))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Indicator
                ProgressIndicator(totalSteps: viewModel.totalSteps, currentStep: viewModel.currentStep)
                    .padding(.top, ResponsivePadding.large)
                    .padding(.bottom, ResponsivePadding.extraLarge)
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    IntroductionStep(viewModel: viewModel)
                        .tag(1)
                    
                    BasicInfoStep(viewModel: viewModel)
                        .tag(2)
                    
                    WelcomeStep(viewModel: viewModel)
                        .tag(3)
                    
                    HealthInfoStep(viewModel: viewModel)
                        .tag(4)
                    
                    LifestyleStep(viewModel: viewModel)
                        .tag(5)
                    
                    SummaryStep(viewModel: viewModel)
                        .tag(6)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                
                // Navigation Buttons
                navigationButtons
            }
        }
        .navigationBarHidden(true)
        .onReceive(viewModel.$shouldNavigateToMain) { shouldNavigate in
            if shouldNavigate {
                onOnboardingComplete?()
                // Navigation will be handled by parent view
            }
        }
    }
}

// MARK: - Navigation Buttons
private extension InteractiveIntroductionView {
    var navigationButtons: some View {
        // Hide global navigation buttons on the first step (IntroductionStep)
        if viewModel.currentStep == 1 {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            HStack {
                if viewModel.currentStep > 1 {
                    CustomButton(
                        title: NSLocalizedString("Onboarding.Back", comment: "Back button"),
                        action: viewModel.previousStep,
                        style: .secondary,
                        innerPadding: ResponsivePadding.small
                    )
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                if viewModel.currentStep < viewModel.totalSteps {
                    CustomButton(
                        title: NSLocalizedString("Onboarding.Next", comment: "Next button"),
                        action: viewModel.nextStep,
                        isEnabled: viewModel.canProceed,
                        innerPadding: ResponsivePadding.small
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    CustomButton(
                        title: isFromProfile ? NSLocalizedString("Onboarding.Update", comment: "Update button") : NSLocalizedString("Onboarding.Finish", comment: "Finish button"),
                        action: { 
                            if isFromProfile {
                                viewModel.updateProfileData()
                            } else {
                                viewModel.finishOnboarding(firestoreManager: firestoreManager, authManager: authManager)
                            }
                        },
                        isLoading: viewModel.isLoading,
                        innerPadding: ResponsivePadding.small
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, ResponsivePadding.large)
            .padding(.bottom, ResponsivePadding.large)
        )
    }
}

