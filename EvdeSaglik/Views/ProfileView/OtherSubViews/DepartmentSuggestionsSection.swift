//
//  DepartmentSuggestionsSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Department Suggestions Section
struct DepartmentSuggestionsSection: View {
    @Binding var showingDepartmentSuggestionHistory: Bool
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.DepartmentSuggestions", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.DepartmentSuggestionHistory", comment: ""),
                    value: NSLocalizedString("Profile.Item.DepartmentSuggestionHistoryValue", comment: ""),
                    icon: "list.bullet",
                    action: { 
                        showingDepartmentSuggestionHistory = true
                    }
                )
            ]
        )
    }
}
