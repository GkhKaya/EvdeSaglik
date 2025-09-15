//
//  RootView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var appStateHolder: AppStateHolder
    
    @State private var showRegisterView = false
    @State private var showOnboardingView = false
    
    var body: some View {
        Group { // Use a Group as the top-level container for all content and modifiers
            switch appStateHolder.appState {
            case .unauthenticated:
                // Unauthenticated state: Login flow within its own NavigationView
                NavigationView {
                    LoginView(onShowRegister: { self.showRegisterView = true })
                        .environmentObject(authManager)
                }
                // Sheet for RegisterView is applied here, as it's part of the unauthenticated flow
                .sheet(isPresented: $showRegisterView) {
                    RegisterView()
                        .environmentObject(authManager)
                        .environmentObject(firestoreManager)
                }
            
            case .onboardingRequired:
                // Onboarding state: InteractiveIntroductionView presented as a fullScreenCover.
                // The base view can be an EmptyView or a loading indicator.
                EmptyView()
            
            case .mainApp:
                // Main app state: Main content within its own NavigationView
                MainAppView() // Present the new MainAppView
                    .environmentObject(authManager)
                    .environmentObject(firestoreManager)
                    .environmentObject(appStateHolder)
            }
        }
        // fullScreenCover for InteractiveIntroductionView, controlled by showOnboardingView
        .fullScreenCover(isPresented: $showOnboardingView) {
            InteractiveIntroductionView(onOnboardingComplete: {
                self.appStateHolder.appState = .mainApp // Signal completion to AppStateHolder
                self.authManager.didJustRegister = false // Reset after onboarding
                self.showOnboardingView = false // Dismiss onboarding after completion
            })
                .environmentObject(authManager)
                .environmentObject(firestoreManager)
                .environmentObject(appStateHolder)
        }
        .onReceive(appStateHolder.$appState) { newState in
            // When appState transitions to onboardingRequired, explicitly show the fullScreenCover
            if newState == .onboardingRequired && !self.showOnboardingView {
                self.showOnboardingView = true
            } else if newState == .unauthenticated {
                self.showOnboardingView = false // Dismiss onboarding if user logs out or is unauthenticated
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(FirebaseAuthManager())
        .environmentObject(FirestoreManager())
        .environmentObject(AppStateHolder())
}
