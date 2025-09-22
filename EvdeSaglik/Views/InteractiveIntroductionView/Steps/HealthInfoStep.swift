//
//  HealthInfoStep.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

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
        NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.Other", comment: ""),
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
