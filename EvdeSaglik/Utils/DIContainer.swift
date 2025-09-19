//
//  DIContainer.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import FirebaseAuth

// MARK: - Dependency Injection Protocols

/// Protocol for dependency injection container
protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
    func resolve<T>(_ type: T.Type, name: String) -> T?
}

/// Simple Dependency Injection Container for managing dependencies
/// Supports both singleton and transient instances
final class DIContainer: DIContainerProtocol {
    
    static let shared = DIContainer()
    
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    
    private init() {
        setupDefaultDependencies()
    }
    
    /// Registers a factory for creating instances of a type
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Registers a singleton instance
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }
    
    /// Resolves an instance of the specified type
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check if singleton exists
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Create new instance using factory
        if let factory = factories[key] {
            let instance = factory() as? T
            return instance
        }
        
        return nil
    }
    
    /// Resolves an instance with a specific name
    func resolve<T>(_ type: T.Type, name: String) -> T? {
        let key = "\(String(describing: type))_\(name)"
        
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        if let factory = factories[key] {
            let instance = factory() as? T
            return instance
        }
        
        return nil
    }
    
    /// Clears all registered dependencies (useful for testing)
    func clear() {
        factories.removeAll()
        singletons.removeAll()
    }
    
    // MARK: - Default Dependencies Setup
    
    private func setupDefaultDependencies() {
        // Register core services
        register(AuthenticationServiceProtocol.self) {
            FirebaseAuthManager()
        }
        
        register(FirestoreServiceProtocol.self) {
            FirestoreManager()
        }
        
        register(AIServiceProtocol.self) {
            OpenRouterDeepseekManager.shared
        }
        
        // Register repositories
        register(DepartmentSuggestionRepositoryProtocol.self) {
            DepartmentSuggestionRepository(firestoreService: self.resolve(FirestoreServiceProtocol.self)!)
        }
        
        // Register UserManager as singleton
        register(UserManager.self) {
            let um = UserManager()
            if let auth = self.resolve(AuthenticationServiceProtocol.self) as? FirebaseAuthManager,
               let fs = self.resolve(FirestoreServiceProtocol.self) as? FirestoreManager {
                um.setup(firestoreManager: fs, authManager: auth)
            }
            return um
        }
    }
}

// MARK: - Convenience Extensions

extension DIContainer {
    
    /// Resolves UserManager
    var userManager: UserManager {
        resolve(UserManager.self)!
    }
    
    /// Resolves AuthenticationService
    var authService: AuthenticationServiceProtocol {
        resolve(AuthenticationServiceProtocol.self)!
    }
    
    /// Resolves FirestoreService
    var firestoreService: FirestoreServiceProtocol {
        resolve(FirestoreServiceProtocol.self)!
    }
    
    /// Resolves AIService
    var aiService: AIServiceProtocol {
        resolve(AIServiceProtocol.self)!
    }
    
    /// Resolves DepartmentSuggestionRepository
    var departmentSuggestionRepository: DepartmentSuggestionRepositoryProtocol {
        resolve(DepartmentSuggestionRepositoryProtocol.self)!
    }
}

// MARK: - Testing Support

extension DIContainer {
    
    /// Registers mock dependencies for testing
    func registerMocks() {
        register(AuthenticationServiceProtocol.self) {
            MockAuthenticationService()
        }
        
        register(FirestoreServiceProtocol.self) {
            MockFirestoreService()
        }
        
        register(AIServiceProtocol.self) {
            MockAIService()
        }
        
        register(DepartmentSuggestionRepositoryProtocol.self) {
            MockDepartmentSuggestionRepository()
        }
    }
}

// MARK: - Mock Implementations for Testing

final class MockAuthenticationService: AuthenticationServiceProtocol {
    var currentUser: User? = nil
    var isAuthenticated: Bool = false
    
    func register(email: String, password: String) async throws {
        // Mock implementation
    }
    
    func login(email: String, password: String) async throws {
        // Mock implementation
    }
    
    func signOut() async throws {
        // Mock implementation
    }
    
    func resetPassword(email: String) async throws {
        // Mock implementation
    }
    
    func updateEmail(_ email: String) async throws {
        // Mock implementation
    }
    
    func updatePassword(_ password: String) async throws {
        // Mock implementation
    }
    
    func deleteAccount() async throws {
        // Mock implementation
    }
}

final class MockFirestoreService: FirestoreServiceProtocol {
    func addDocument<T: Codable>(to collection: String, object: T) async throws {
        // Mock implementation
    }
    
    func updateDocument<T: Codable>(in collection: String, documentId: String, object: T) async throws {
        // Mock implementation
    }
    
    func deleteDocument(from collection: String, documentId: String) async throws {
        // Mock implementation
    }
    
    func fetchDocument<T: Codable>(from collection: String, documentId: String, as type: T.Type) async throws -> T? {
        return nil
    }
    
    func queryDocuments<T: Codable>(from collection: String, where field: String, isEqualTo value: Any, as type: T.Type) async throws -> [T] {
        return []
    }
}

final class MockAIService: AIServiceProtocol {
    func performChatRequest(messages: [DeepseekMessage]) async throws -> String {
        return "Mock AI response"
    }
    
    func generateUserSummary(userData: UserModel) async throws -> String {
        return "Mock user summary"
    }
}
