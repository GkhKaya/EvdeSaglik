//
//  AboutAppView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 22.09.2025.
//

import SwiftUI

struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ResponsivePadding.large) {
                    // App Header
                    appHeader
                    
                    // Developer Info
                    developerSection
                    
                    // App Purpose
                    purposeSection
                    
                    Spacer(minLength: ResponsivePadding.extraLarge)
                }
                .padding(.horizontal, ResponsivePadding.large)
            }
            .navigationTitle(NSLocalizedString("AboutApp.Title", comment: "About App"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Common.Close", comment: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - App Header
private extension AboutAppView {
    var appHeader: some View {
        VStack(spacing: ResponsivePadding.medium) {
            // App Logo
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: ResponsiveRadius.large))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // App Name
            Text(NSLocalizedString("AboutApp.AppName", comment: "App Name"))
                .font(.title1Responsive)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // App Version
            Text(NSLocalizedString("AboutApp.Version", comment: "Version"))
                .font(.subheadlineResponsive)
                .foregroundStyle(.secondary)
                .padding(.horizontal, ResponsivePadding.medium)
                .padding(.vertical, ResponsivePadding.small)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(.vertical, ResponsivePadding.large)
    }
}

// MARK: - Developer Section
private extension AboutAppView {
    var developerSection: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            Text(NSLocalizedString("AboutApp.Developer.Title", comment: "Developer"))
                .font(.headlineResponsive)
                .fontWeight(.semibold)
            
            VStack(spacing: ResponsivePadding.small) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2Responsive)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("AboutApp.Developer.Name", comment: "Developer Name"))
                            .font(.bodyResponsive)
                            .fontWeight(.medium)
                        
                        Text(NSLocalizedString("AboutApp.Developer.Role", comment: "Developer Role"))
                            .font(.captionResponsive)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "globe")
                        .font(.title2Responsive)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("AboutApp.Developer.Website", comment: "Website"))
                            .font(.bodyResponsive)
                            .fontWeight(.medium)
                        
                        Text("gkhkaya.info")
                            .font(.captionResponsive)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let url = URL(string: "https://gkhkaya.info") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.bodyResponsive)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(ResponsivePadding.medium)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Purpose Section
private extension AboutAppView {
    var purposeSection: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            Text(NSLocalizedString("AboutApp.Purpose.Title", comment: "Purpose"))
                .font(.headlineResponsive)
                .fontWeight(.semibold)
            
            Text(NSLocalizedString("AboutApp.Purpose.Description", comment: "Purpose Description"))
                .font(.bodyResponsive)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(ResponsivePadding.medium)
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

#Preview {
    AboutAppView()
}
