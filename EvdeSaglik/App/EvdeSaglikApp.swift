//
//  EvdeSaglikApp.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 13.09.2025.
//

import SwiftUI
import FirebaseCore
import Combine // Added for Combine publishers
import FirebaseAuth // Add this import

enum AppState {
    case unauthenticated
    case onboardingRequired
    case mainApp
}

// A simple ObservableObject to hold and manage the AppState
class AppStateHolder: ObservableObject {
    @Published var appState: AppState = .unauthenticated
    
    // Dependencies will be injected via environmentObjects or directly
    var authManager: FirebaseAuthManager? // Will be set by EvdeSaglikApp
    var firestoreManager: FirestoreManager? // Will be set by EvdeSaglikApp
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Setup observers here once managers are set, or use a setup function
    }
    
    func setupObservers(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        self.authManager = authManager
        self.firestoreManager = firestoreManager
        
        // Call initial status check here, after managers are set
        checkAuthenticationStatus()
        
        authManager.$currentUser
            .sink { [weak self] user in
                self?.handleAuthChange(user: user)
            }
            .store(in: &cancellables)
        
        authManager.$didJustRegister
            .sink { [weak self] didRegister in
                // Only trigger onboarding if a new registration just occurred and user is authenticated
                // and onboarding is not yet complete.
                if didRegister && self?.appState == .unauthenticated || self?.appState == .onboardingRequired {
                    // If just registered and not yet onboarded, force onboarding
                    self?.appState = .onboardingRequired
                    // `didJustRegister` will be reset by InteractiveIntroductionView on completion
                }
            }
            .store(in: &cancellables)
        
    }
    
    private func handleAuthChange(user: User?) {
        if let user = user {
            // User is authenticated, check onboarding status
            fetchOnboardingStatus(for: user.uid)
        } else {
            // User is not authenticated
            appState = .unauthenticated
        }
    }
    
    private func checkAuthenticationStatus() {
        if let user = authManager?.getCurrentUser() {
            handleAuthChange(user: user)
        } else {
            appState = .unauthenticated
        }
    }
    
    private func fetchOnboardingStatus(for userId: String) {
        firestoreManager?.fetchDocument(collection: "users", documentId: userId) { [weak self] (result: Result<UserModel?, AppError>) in
            switch result {
            case .success(let userModel):
                if userModel?.isOnboardingCompleted == true {
                    self?.appState = .mainApp
                } else {
                    self?.appState = .onboardingRequired
                }
            case .failure(let error):
                print("Error fetching user onboarding status: \(error.localizedDescription)")
                self?.appState = .onboardingRequired // Assume onboarding needed on error
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


@main
struct EvdeSaglikApp: App {
    
    @StateObject var firestoreManager = FirestoreManager()
    @StateObject var authManager = FirebaseAuthManager()
    @StateObject var appStateHolder = AppStateHolder()
    @StateObject var userManager = UserManager() // Initialize without parameters
    
    // The init() method causing issues is now correctly removed.
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(firestoreManager)
                .environmentObject(appStateHolder) // Inject AppStateHolder
                .environmentObject(userManager) // Inject UserManager
                .onAppear { // Setup observers after environment objects are available
                    appStateHolder.setupObservers(authManager: authManager, firestoreManager: firestoreManager)
                    userManager.setup(firestoreManager: firestoreManager, authManager: authManager) // Setup UserManager with actual managers
                }
        }
    }
    
    // All navigation and state properties moved to AppStateHolder and RootView
    // No longer needed here.
}
