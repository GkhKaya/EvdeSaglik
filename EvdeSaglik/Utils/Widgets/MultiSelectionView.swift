//
//  MultiSelectionView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct MultiSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selectedOptions: [String]
    let columns: Int
    
    init(title: String, options: [String], selectedOptions: Binding<[String]>, columns: Int = 2) {
        self.title = title
        self.options = options
        self._selectedOptions = selectedOptions
        self.columns = columns
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            Text(title)
                .font(.subheadlineResponsive)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ResponsivePadding.small), count: columns), spacing: ResponsivePadding.small) {
                ForEach(options, id: \.self) { option in
                    SelectionButton(
                        title: option,
                        isSelected: selectedOptions.contains(option),
                        action: { toggleSelection(option) }
                    )
                }
            }
        }
    }
    
    private func toggleSelection(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.removeAll { $0 == option }
        } else {
            selectedOptions.append(option)
        }
    }
}

#Preview {
    MultiSelectionView(
        title: "Kronik Hastalıklarınız",
        options: ["Diyabet", "Hipertansiyon", "Astım", "Kalp Hastalığı"],
        selectedOptions: .constant(["Diyabet"])
    )
    .padding()
}

