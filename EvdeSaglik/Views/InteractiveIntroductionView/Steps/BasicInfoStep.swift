//
//  BasicInfoStep.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

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
