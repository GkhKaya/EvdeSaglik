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
    @Published var isInitializing: Bool = true // New property to indicate initial state determination
    
    // Dependencies will be injected via environmentObjects or directly
    var authManager: FirebaseAuthManager? // Will be set by EvdeSaglikApp
    var firestoreManager: FirestoreManager? // Will be set by EvdeSaglikApp
    var userManager: UserManager? // Will be set by EvdeSaglikApp
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize appState directly here to ensure unauthenticated state from the start.
        self.appState = .unauthenticated
    }
    
    // MARK: - Setup and Initialization
    func setupObservers(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager, userManager: UserManager) {
        self.authManager = authManager
        self.firestoreManager = firestoreManager
        self.userManager = userManager
        
        // Observe changes in currentUser from AuthManager
        authManager.$currentUser
            .sink { [weak self] user in
                self?.handleAuthChange(user: user)
            }
            .store(in: &cancellables)
            
        // Observe didJustRegister flag from AuthManager
        authManager.$didJustRegister
            .sink { [weak self] didJustRegister in
                if didJustRegister && self?.authManager?.currentUser != nil {
                    DispatchQueue.main.async { // Ensure UI updates are on the main thread
                        self?.appState = .onboardingRequired
                    }
                }
            }
            .store(in: &cancellables)
            
        // Removed immediate checkAuthenticationStatus() here, it will be called by setupInitialAppState()
    }
    
    func setupInitialAppState() {
        isInitializing = true
        
        // Use a lightweight async mechanism to wait for Firebase Auth to settle
        // or ensure it's checked after a slight delay.
        // For a simple app, checking currentUser directly might be sufficient, but
        // for robustness, we can use a small delay or a more advanced Combine/Async method.
        
        // For now, let's re-use checkAuthenticationStatus, but ensure it's called after
        // setupObservers, and consider its async nature.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in // Add a small delay
            self?.checkAuthenticationStatus() // Call the existing logic
            DispatchQueue.main.async {
                self?.isInitializing = false
            }
        }
    }
    
    private func handleAuthChange(user: User?) {
        if let user = user {
            // User is signed in, check onboarding status
            fetchOnboardingStatus(userID: user.uid) // Pass userID here
        } else {
            // User is signed out
            DispatchQueue.main.async {
                // Only set to unauthenticated if rememberMe is false
                // If rememberMe is true, and currentUser is nil, it means user was logged out for other reasons, still show login
                // This state will be handled by remember me logic during initial check or explicit logout.
                self.appState = .unauthenticated
            }
        }
    }
    
    func checkAuthenticationStatus() { // Changed from private to internal
        // Check if user is already authenticated on app launch
        if let user = Auth.auth().currentUser {
            if authManager?.getRememberMe() == true {
                // If remembered, fetch onboarding status
                fetchOnboardingStatus(userID: user.uid)
            } else {
                // Not remembered, sign out and go to login
                Task { [weak self] in
                    do {
                        try await self?.authManager?.signOut()
                    } catch {
                        // ignore error; auth sink will handle state
                    }
                }
            }
        } else {
            // No user is signed in, go to unauthenticated state
            DispatchQueue.main.async {
                self.appState = .unauthenticated
            }
        }
    }
    
    private func fetchOnboardingStatus(userID: String) {
        Task { [weak self] in
            guard let self = self, let firestoreManager = self.firestoreManager else { return }
            do {
                let userModel: UserModel? = try await firestoreManager.fetchDocument(from: "users", documentId: userID, as: UserModel.self)
                await MainActor.run {
                    if let userModel = userModel {
                        if userModel.isOnboardingCompleted && userModel.isInformationHas {
                            self.appState = .mainApp
                        } else {
                            self.appState = .onboardingRequired
                        }
                    } else {
                        self.appState = .onboardingRequired
                    }
                }
            } catch {
                print("Error fetching user profile: \(error)")
                await MainActor.run { self.appState = .onboardingRequired }
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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // Uncomment this line
    var body: some Scene {
        WindowGroup {
            RootView() // Set RootView as the root view directly
                .environmentObject(authManager)
                .environmentObject(firestoreManager)
                .environmentObject(appStateHolder) // Inject AppStateHolder
                .environmentObject(userManager) // Inject UserManager
                .onAppear {
                    // Configure UserManager with its dependencies
                    userManager.setup(firestoreManager: firestoreManager, authManager: authManager)
                    // Setup AppStateHolder observers
                    appStateHolder.setupObservers(authManager: authManager, firestoreManager: firestoreManager, userManager: userManager)
                    // Call the new initial setup function
                    appStateHolder.setupInitialAppState()
                }
        }
    }
    
    // All navigation and state properties moved to AppStateHolder and RootView
    // No longer needed here.
}
