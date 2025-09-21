//
//  AccountSettingsSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Account Settings Section
struct AccountSettingsSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.AccountSettings", comment: ""),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.ChangeEmail", comment: ""),
                    value: NSLocalizedString("Profile.Item.ChangeEmailValue", comment: ""),
                    icon: "envelope",
                    action: { viewModel.showingChangeEmail = true }
                ),
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.ChangePassword", comment: ""),
                    value: NSLocalizedString("Profile.Item.ChangePasswordValue", comment: ""),
                    icon: "key",
                    action: { viewModel.showingChangePassword = true }
                ),
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.Personalization", comment: ""),
                    value: NSLocalizedString("Profile.Item.PersonalizationValue", comment: ""),
                    icon: "person.crop.circle",
                    action: { viewModel.showingPersonalization = true }
                )
            ]
        )
    }
}
