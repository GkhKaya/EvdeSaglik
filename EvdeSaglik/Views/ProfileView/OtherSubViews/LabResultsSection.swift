//
//  LabResultsSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Lab Results Section
struct LabResultsSection: View {
    @Binding var showingLabResultHistory: Bool
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.LabResults", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.LabResultHistory", comment: ""),
                    value: NSLocalizedString("Profile.Item.LabResultHistoryValue", comment: ""),
                    icon: "list.bullet",
                    action: { 
                        showingLabResultHistory = true
                    }
                )
            ]
        )
    }
}
