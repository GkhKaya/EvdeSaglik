//
//  MultiSelectionWithCustomView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct MultiSelectionWithCustomView: View {
    let title: String
    let options: [String]
    @Binding var selectedOptions: [String]
    @State private var customInput: String = ""
    @State private var showCustomInput: Bool = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            // Title
            Text(title)
                .font(.subheadlineResponsive)
                .fontWeight(.medium)
            
            // Options grid
            LazyVGrid(columns: columns, spacing: ResponsivePadding.small) {
                ForEach(options, id: \.self) { option in
                    SelectionButton(
                        title: option,
                        isSelected: selectedOptions.contains(option),
                        action: { toggleOption(option) }
                    )
                }
                
                // Custom option button
                SelectionButton(
                    title: NSLocalizedString("Onboarding.CustomOption", comment: "Custom option"),
                    isSelected: showCustomInput,
                    action: { showCustomInput.toggle() }
                )
            }
            
            // Custom input field
            if showCustomInput {
                VStack(spacing: ResponsivePadding.small) {
                    CustomTextField(
                        title: "",
                        placeholder: NSLocalizedString("Onboarding.CustomOptionPlaceholder", comment: "Custom option placeholder"),
                        icon: "pencil",
                        text: $customInput
                    )
                    
                    HStack {
                        Button(action: addCustomOption) {
                            Text(NSLocalizedString("Onboarding.Add", comment: "Add button"))
                                .font(.subheadlineResponsive)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                        }
                        .disabled(customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Spacer()
                        
                        Button(action: { 
                            showCustomInput = false 
                            customInput = ""
                        }) {
                            Text(NSLocalizedString("Onboarding.Cancel", comment: "Cancel button"))
                                .font(.subheadlineResponsive)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(ResponsivePadding.small)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                        .fill(Color(.tertiarySystemBackground))
                )
            }
            
            // Selected options display
            if !selectedOptions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ResponsivePadding.small) {
                        ForEach(selectedOptions, id: \.self) { option in
                            HStack(spacing: ResponsivePadding.xSmall) {
                                Text(option)
                                    .font(.caption1Responsive)
                                    .foregroundStyle(.blue)
                                
                                Button(action: { removeOption(option) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption1Responsive)
                                        .foregroundStyle(.blue.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, ResponsivePadding.small)
                            .padding(.vertical, ResponsivePadding.xSmall)
                            .background(
                                RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
    
    private func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.removeAll { $0 == option }
        } else {
            selectedOptions.append(option)
        }
    }
    
    private func addCustomOption() {
        let trimmedInput = customInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInput.isEmpty && !selectedOptions.contains(trimmedInput) {
            selectedOptions.append(trimmedInput)
            customInput = ""
            showCustomInput = false
        }
    }
    
    private func removeOption(_ option: String) {
        selectedOptions.removeAll { $0 == option }
    }
}

#Preview {
    @Previewable @State var selectedOptions = ["Diyabet", "Hipertansiyon"]
    
    return MultiSelectionWithCustomView(
        title: "Kronik Hastalıklar",
        options: ["Diyabet", "Hipertansiyon", "Astım", "Kalp Hastalığı"],
        selectedOptions: $selectedOptions
    )
    .padding()
}

