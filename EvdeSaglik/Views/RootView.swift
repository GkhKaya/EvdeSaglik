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
    // Removed @State private var showOnboardingView = false as it's no longer needed for fullScreenCover
    
    var body: some View {
        Group { // Use a Group as the top-level container for all content and modifiers
            if appStateHolder.isInitializing {
                // Display a loading indicator while the app state is being determined
                ProgressView(NSLocalizedString("Loading.Initializing", comment: "Initializing app"))
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
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
                    // Onboarding state: InteractiveIntroductionView presented directly.
                    InteractiveIntroductionView(firestoreManager: firestoreManager, authManager: authManager, onOnboardingComplete: {
                        self.appStateHolder.appState = .mainApp // Signal completion to AppStateHolder
                        self.authManager.didJustRegister = false // Reset after onboarding
                    })
                        .environmentObject(authManager)
                        .environmentObject(firestoreManager)
                        .environmentObject(appStateHolder)
                
                case .mainApp:
                    // Main app state: Main content within its own NavigationView
                    MainAppView() // Present the new MainAppView
                        .environmentObject(authManager)
                        .environmentObject(firestoreManager)
                        .environmentObject(appStateHolder)
                }
            }
        }
        .onAppear { // Move .onAppear here to apply to the Group
            // Re-check authentication status every time RootView appears
            appStateHolder.checkAuthenticationStatus()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(FirebaseAuthManager())
        .environmentObject(FirestoreManager())
        .environmentObject(AppStateHolder())
        .environmentObject(UserManager())
}
