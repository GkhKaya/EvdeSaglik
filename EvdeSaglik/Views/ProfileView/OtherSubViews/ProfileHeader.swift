//
//  ProfileHeader.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

// MARK: - Profile Header
struct ProfileHeader: View {
    let userName: String
    let userEmail: String
    
    var body: some View {
        VStack(spacing: ResponsivePadding.medium) {
            // Profile Avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            // User Info
            VStack(spacing: ResponsivePadding.small) {
                Text(userName.isEmpty ? NSLocalizedString("Profile.UserName", comment: "") : userName)
                    .font(.title2Responsive)
                    .fontWeight(.semibold)
                
                Text(userEmail)
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, ResponsivePadding.large)
    }
}
