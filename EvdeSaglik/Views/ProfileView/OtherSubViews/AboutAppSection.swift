//
//  AboutAppSection.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 22.09.2025.
//

import SwiftUI

struct AboutAppSection: View {
    @Binding var showingAboutApp: Bool
    
    var body: some View {
        ProfileSection(
            title: NSLocalizedString("Profile.Section.AboutApp", comment: "About App"),
            items: [
                ProfileItem(
                    title: NSLocalizedString("Profile.Item.AboutApp", comment: "About App"),
                    value: NSLocalizedString("Profile.Item.AboutAppValue", comment: "App information and developer details"),
                    icon: "info.circle",
                    action: { showingAboutApp = true },
                    isDestructive: false
                )
            ]
        )
    }
}
