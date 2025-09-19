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
                    
                    HealthInfoStep(viewModel: viewModel)
                        .tag(3)
                    
                    LifestyleStep(viewModel: viewModel)
                        .tag(4)
                    
                    SummaryStep(viewModel: viewModel)
                        .tag(5)
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
                        innerPadding: ResponsivePadding.small // Smaller padding
                    )
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                if viewModel.currentStep < viewModel.totalSteps {
                    CustomButton(
                        title: NSLocalizedString("Onboarding.Next", comment: "Next button"),
                        action: viewModel.nextStep,
                        isEnabled: viewModel.canProceed,
                        innerPadding: ResponsivePadding.small // Smaller padding
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
                        innerPadding: ResponsivePadding.small // Smaller padding
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, ResponsivePadding.large)
            .padding(.bottom, ResponsivePadding.large)
        )
    }
}

// MARK: - Step 1: Introduction
struct IntroductionStep: View {
    @ObservedObject var viewModel: InteractiveIntroductionViewModel
    
    var body: some View {
        VStack(spacing: ResponsivePadding.large) {
            // Icon
            Image(systemName: "heart.text.square.fill")
                .font(.largeTitleResponsive) // Using responsive font modifier
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
                    innerPadding: ResponsivePadding.small // Smaller padding
                )
                .frame(maxWidth: .infinity)
                
                CustomButton(
                    title: NSLocalizedString("Onboarding.Next", comment: "Continue button"),
                    action: viewModel.nextStep,
                    innerPadding: ResponsivePadding.small // Smaller padding
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, ResponsivePadding.large)
    }
}

// MARK: - Step 2: Basic Information
struct BasicInfoStep: View {
    @ObservedObject var viewModel: InteractiveIntroductionViewModel
    
    private let genderOptions = [
        NSLocalizedString("Onboarding.BasicInfo.Gender.Male", comment: ""),
        NSLocalizedString("Onboarding.BasicInfo.Gender.Female", comment: ""),
        NSLocalizedString("Onboarding.BasicInfo.Gender.Other", comment: "")
    ]
    private let ageOptions = Array(18...100).map { "\($0)" }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ResponsivePadding.large) {
                // Header
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("Onboarding.BasicInfo.Title", comment: "Basic info title"))
                        .font(.title2Responsive)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("Onboarding.BasicInfo.Description", comment: "Basic info description"))
                        .font(.bodyResponsive)
                        .foregroundStyle(.secondary)
                }
                
                // Name Field
                CustomTextField(
                    title: NSLocalizedString("Onboarding.BasicInfo.Name", comment: "Name field"),
                    placeholder: NSLocalizedString("Onboarding.BasicInfo.NamePlaceholder", comment: "Name placeholder"),
                    icon: "person",
                    text: $viewModel.userModel.fullName
                )
                
                // Gender Selection
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("Onboarding.BasicInfo.Gender", comment: "Gender field"))
                        .font(.subheadlineResponsive)
                        .fontWeight(.medium)
                    
                    HStack(spacing: ResponsivePadding.small) {
                        ForEach(genderOptions, id: \.self) { gender in
                            SelectionButton(
                                title: gender,
                                isSelected: viewModel.selectedGender == gender,
                                action: { viewModel.selectedGender = gender }
                            )
                        }
                    }
                }
                
                // Age Selection
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("Onboarding.BasicInfo.Age", comment: "Age field"))
                        .font(.subheadlineResponsive)
                        .fontWeight(.medium)
                    
                    Menu {
                        ForEach(ageOptions, id: \.self) { age in
                            Button(age) {
                                viewModel.selectedAge = age
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedAge.isEmpty ? NSLocalizedString("Onboarding.BasicInfo.AgeSelect", comment: "Select age") : viewModel.selectedAge)
                                .foregroundStyle(viewModel.selectedAge.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .padding(ResponsivePadding.medium)
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                .strokeBorder(Color(.separator), lineWidth: 1)
                                .background(Color(.systemBackground))
                        )
                    }
                }
                
                Spacer(minLength: ResponsivePadding.extraLarge)
            }
            .padding(.horizontal, ResponsivePadding.large)
        }
    }
}

// MARK: - Step 3: Health Information
struct HealthInfoStep: View {
    @ObservedObject var viewModel: InteractiveIntroductionViewModel
    
    private let chronicDiseaseOptions = [
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.Diabetes", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.Hypertension", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.Asthma", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.HeartDisease", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.KidneyDisease", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.LiverDisease", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.Thyroid", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.None", comment: "")
    ]
    
    private let allergyOptions = [
        NSLocalizedString("Onboarding.HealthInfo.Allergies.Medication", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Allergies.Food", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Allergies.Pollen", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Allergies.Animal", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Allergies.Dust", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Allergies.Other", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Allergies.Unknown", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Allergies.None", comment: "")
    ]
    
    private let medicationOptions = [
        NSLocalizedString("Onboarding.HealthInfo.Medications.BloodPressure", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Medications.Diabetes", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Medications.Heart", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Medications.Painkiller", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Medications.Vitamin", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Medications.Antidepressant", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Medications.Other", comment: ""),
        NSLocalizedString("Onboarding.HealthInfo.Medications.None", comment: "")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ResponsivePadding.large) {
                // Header
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("Onboarding.HealthInfo.Title", comment: "Health info title"))
                        .font(.title2Responsive)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("Onboarding.HealthInfo.Description", comment: "Health info description"))
                        .font(.bodyResponsive)
                        .foregroundStyle(.secondary)
                }
                
                // Chronic Diseases
                MultiSelectionWithCustomView(
                    title: NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases", comment: "Chronic diseases"),
                    options: chronicDiseaseOptions,
                    selectedOptions: $viewModel.selectedChronicDiseases
                )
                
                // Allergies
                MultiSelectionWithCustomView(
                    title: NSLocalizedString("Onboarding.HealthInfo.Allergies", comment: "Allergies"),
                    options: allergyOptions,
                    selectedOptions: $viewModel.selectedAllergies
                )
                
                // Medications
                MultiSelectionWithCustomView(
                    title: NSLocalizedString("Onboarding.HealthInfo.Medications", comment: "Medications"),
                    options: medicationOptions,
                    selectedOptions: $viewModel.selectedMedications
                )
                
                Spacer(minLength: ResponsivePadding.extraLarge)
            }
            .padding(.horizontal, ResponsivePadding.large)
        }
    }
}

// MARK: - Step 4: Lifestyle
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

// MARK: - Step 5: Summary
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
                
                Spacer(minLength: ResponsivePadding.extraLarge)
            }
            .padding(.horizontal, ResponsivePadding.large)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            Text(title)
                .font(.subheadlineResponsive)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            
            Text(content)
                .font(.subheadlineResponsive)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ResponsivePadding.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

