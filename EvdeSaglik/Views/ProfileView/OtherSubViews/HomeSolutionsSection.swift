//
//  HomeSolutionsSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Home Solutions Section
struct HomeSolutionsSection: View {
    @Binding var showingHomeSolutionHistory: Bool
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.HomeSolutions", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.HomeSolutionHistory", comment: ""),
                    value: NSLocalizedString("Profile.Item.HomeSolutionHistoryValue", comment: ""),
                    icon: "list.bullet",
                    action: { 
                        showingHomeSolutionHistory = true
                    }
                )
            ]
        )
    }
}
