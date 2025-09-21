//
//  DangerZoneSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Danger Zone Section
struct DangerZoneSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.DangerZone", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.DeleteAccount", comment: ""),
                    value: NSLocalizedString("Profile.Item.DeleteAccountValue", comment: ""),
                    icon: "trash",
                    action: { viewModel.showingDeleteAccount = true },
                    isDestructive: true
                )
            ]
        )
    }
}
