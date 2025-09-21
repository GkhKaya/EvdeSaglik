//
//  NaturalSolutionsSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Natural Solutions Section
struct NaturalSolutionsSection: View {
    @Binding var showingNaturalSolutionHistory: Bool
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.NaturalSolutions", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.NaturalSolutionHistory", comment: ""),
                    value: NSLocalizedString("Profile.Item.NaturalSolutionHistoryValue", comment: ""),
                    icon: "list.bullet",
                    action: { 
                        showingNaturalSolutionHistory = true
                    }
                )
            ]
        )
    }
}
