//
//  DepartmentSuggestionRepository.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation

// MARK: - Repository Protocols

/// Protocol for department suggestion operations
protocol DepartmentSuggestionRepositoryProtocol {
    func saveSuggestion(_ suggestion: DepartmentSuggestionModel) async throws
    func fetchUserSuggestions(userId: String) async throws -> [DepartmentSuggestionModel]
    func deleteSuggestion(_ suggestionId: String) async throws
}

/// Protocol for disease prediction operations
protocol DiseasePredictionRepositoryProtocol {
    func savePrediction(_ prediction: DiseasePredictionModel) async throws
    func fetchUserPredictions(userId: String) async throws -> [DiseasePredictionModel]
    func deletePrediction(_ predictionId: String) async throws
}

/// Protocol for home solution operations
protocol HomeSolutionRepositoryProtocol {
    func saveSolution(_ solution: HomeSolutionModel) async throws
    func fetchUserSolutions(userId: String) async throws -> [HomeSolutionModel]
    func deleteSolution(_ solutionId: String) async throws
}

/// Protocol for lab result operations
protocol LabResultRepositoryProtocol {
    func saveLabResult(_ labResult: LabResultRecommendationModel) async throws
    func fetchUserLabResults(userId: String) async throws -> [LabResultRecommendationModel]
    func deleteLabResult(_ labResultId: String) async throws
}

/// Protocol for natural solution operations
protocol NaturalSolutionRepositoryProtocol {
    func saveNaturalSolution(_ solution: NaturalSolitionsModel) async throws
    func fetchUserNaturalSolutions(userId: String) async throws -> [NaturalSolitionsModel]
    func deleteNaturalSolution(_ solutionId: String) async throws
}

/// Repository implementation for Department Suggestion operations
/// Provides a clean interface for data operations and can be easily mocked for testing
final class DepartmentSuggestionRepository: DepartmentSuggestionRepositoryProtocol {
    
    private let firestoreService: FirestoreServiceProtocol
    
    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }
    
    /// Saves a department suggestion to Firestore
    func saveSuggestion(_ suggestion: DepartmentSuggestionModel) async throws {
        try await firestoreService.addDocument(to: "departmentSuggestions", object: suggestion)
    }
    
    /// Fetches all department suggestions for a specific user
    func fetchUserSuggestions(userId: String) async throws -> [DepartmentSuggestionModel] {
        return try await firestoreService.queryDocuments(
            from: "departmentSuggestions",
            where: "userId",
            isEqualTo: userId,
            as: DepartmentSuggestionModel.self
        )
    }
    
    /// Deletes a specific department suggestion
    func deleteSuggestion(_ suggestionId: String) async throws {
        try await firestoreService.deleteDocument(from: "departmentSuggestions", documentId: suggestionId)
    }
}

/// Mock implementation for testing purposes
final class MockDepartmentSuggestionRepository: DepartmentSuggestionRepositoryProtocol {
    
    var suggestions: [DepartmentSuggestionModel] = []
    var shouldThrowError = false
    var lastSavedSuggestion: DepartmentSuggestionModel?
    var lastDeletedSuggestionId: String?
    
    func saveSuggestion(_ suggestion: DepartmentSuggestionModel) async throws {
        if shouldThrowError {
            throw AppError.firestoreError(.writeFailed("Mock error"))
        }
        lastSavedSuggestion = suggestion
        suggestions.append(suggestion)
    }
    
    func fetchUserSuggestions(userId: String) async throws -> [DepartmentSuggestionModel] {
        if shouldThrowError {
            throw AppError.firestoreError(.readFailed("Mock error"))
        }
        return suggestions.filter { $0.userId == userId }
    }
    
    func deleteSuggestion(_ suggestionId: String) async throws {
        if shouldThrowError {
            throw AppError.firestoreError(.writeFailed("Mock error"))
        }
        lastDeletedSuggestionId = suggestionId
        suggestions.removeAll { $0.id == suggestionId }
    }
}
