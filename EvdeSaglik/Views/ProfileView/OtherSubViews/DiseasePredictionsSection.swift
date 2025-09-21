//
//  DiseasePredictionsSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Disease Predictions Section
struct DiseasePredictionsSection: View {
    @Binding var showingDiseasePredictionHistory: Bool
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.DiseasePredictions", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.DiseasePredictionHistory", comment: ""),
                    value: NSLocalizedString("Profile.Item.DiseasePredictionHistoryValue", comment: ""),
                    icon: "list.bullet",
                    action: { 
                        showingDiseasePredictionHistory = true
                    }
                )
            ]
        )
    }
}
