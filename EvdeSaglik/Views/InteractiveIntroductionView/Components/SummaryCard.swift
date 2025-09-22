//
//  SummaryCard.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

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
