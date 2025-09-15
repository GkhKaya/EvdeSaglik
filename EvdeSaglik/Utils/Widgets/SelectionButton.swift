//
//  SelectionButton.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bodyResponsive)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(ResponsivePadding.medium)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                        .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    VStack {
        SelectionButton(title: "Erkek", isSelected: true, action: {})
        SelectionButton(title: "Kadın", isSelected: false, action: {})
    }
    .padding()
}

