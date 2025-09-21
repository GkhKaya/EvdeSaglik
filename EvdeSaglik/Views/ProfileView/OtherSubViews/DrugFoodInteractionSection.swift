//
//  DrugFoodInteractionSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Drug Food Interaction Section
struct DrugFoodInteractionSection: View {
    @Binding var showingDrugFoodInteractionHistory: Bool
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.DrugFoodInteraction", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.DrugFoodInteractionHistory", comment: ""),
                    value: NSLocalizedString("Profile.Item.DrugFoodInteractionHistoryValue", comment: ""),
                    icon: "list.bullet",
                    action: { 
                        showingDrugFoodInteractionHistory = true
                    }
                )
            ]
        )
    }
}
