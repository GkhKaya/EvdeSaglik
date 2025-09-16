//
//  MainAppView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var appStateHolder: AppStateHolder
    @EnvironmentObject var userManager: UserManager // Inject UserManager
    
    @State private var searchQuery: String = ""
    @State private var showingPersonalizeSheet: Bool = false
    @State private var showingChatbot: Bool = false // New state for chatbot
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ResponsivePadding.medium) {
                    // Search Bar (now triggers chatbot)
                    CustomTextField(
                        title: NSLocalizedString("MainApp.SearchBar.Title", comment: "Search bar title"),
                        placeholder: NSLocalizedString("MainApp.SearchBar.Placeholder", comment: "Search bar placeholder"),
                        icon: "magnifyingglass",
                        text: $searchQuery,
                        onIconTap: {
                            showingChatbot = true
                        }
                    )
                    .onTapGesture {
                        showingChatbot = true // textfield'a dokununca da aç
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    
                    // Personalize Button
                    HStack {
                        Spacer()
                        Button(action: {
                            showingPersonalizeSheet = true
                        }) {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                Text(NSLocalizedString("MainApp.PersonalizeButton", comment: "Personalize button"))
                            }
                            .font(.subheadlineResponsive)
                            .padding(.vertical, ResponsivePadding.small)
                            .padding(.horizontal, ResponsivePadding.medium)
                            .background(Capsule().fill(Color.accentColor))
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal, ResponsivePadding.large)
                    }
                    
                    // Quick Access Cards Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: UIScreen.screenWidth / 2 - ResponsivePadding.extraLarge))]) {
                        MainFeatureCard(
                            title: NSLocalizedString("MainApp.Card.Doctor", comment: "Which doctor should I go to?"),
                            icon: "stethoscope",
                            action: {}
                        )
                        MainFeatureCard(
                            title: NSLocalizedString("MainApp.Card.Disease", comment: "What could be my disease?"),
                            icon: "cross.case",
                            action: {}
                        )
                        MainFeatureCard(
                            title: NSLocalizedString("MainApp.Card.HomeRemedies", comment: "What can I do at home?"),
                            icon: "house", // Changed from "house.medical" to "house"
                            action: {}
                        )
                        MainFeatureCard(
                            title: NSLocalizedString("MainApp.Card.LabResults", comment: "Lab test results"),
                            icon: "doc.text.magnifyingglass",
                            action: {}
                        )
                        MainFeatureCard(
                            title: NSLocalizedString("MainApp.Card.NaturalSolutions", comment: "Natural solutions"),
                            icon: "leaf.fill",
                            action: {}
                        )
                        MainFeatureCard(
                            title: NSLocalizedString("MainApp.Card.SkinProblems", comment: "Skin problems"),
                            icon: "face.dashed",
                            action: {}
                        )
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                }
                .padding(.top, ResponsivePadding.medium)
            }
            .navigationTitle(NSLocalizedString("MainApp.Title", comment: "Main App Title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPersonalizeSheet) {
                // Personalization View
                Text(NSLocalizedString("MainApp.PersonalizeSheet.Title", comment: "Personalize Sheet Title"))
            }
            // Present ChatbotView as a fullScreenCover with animation
            .fullScreenCover(isPresented: $showingChatbot, onDismiss: {
                searchQuery = "" // Clear search query when chatbot is dismissed
            }) {
                ChatbotView(authManager: authManager, firestoreManager: firestoreManager, userManager: userManager, initialMessage: searchQuery)
                    .transition(.move(edge: .bottom)) // Animasyon aşağıdan yukarıya doğru
            }
        }
    }
}

// MARK: - MainFeatureCard
struct MainFeatureCard: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ResponsivePadding.small) {
                Image(systemName: icon)
                    .font(.title1Responsive)
                    .foregroundStyle(Color.accentColor)
                
                Text(title)
                    .font(.bodyResponsive)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(ResponsivePadding.medium)
            .frame(maxWidth: .infinity, minHeight: UIScreen.screenWidth * 0.3)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.systemGray).opacity(0.2), radius: 5, x: 0, y: 5)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(PlainButtonStyle()) // To prevent default button styling
    }
}

// MARK: - Preview
#Preview {
    MainAppView()
        .environmentObject(FirebaseAuthManager())
        .environmentObject(FirestoreManager())
        .environmentObject(AppStateHolder())
}
