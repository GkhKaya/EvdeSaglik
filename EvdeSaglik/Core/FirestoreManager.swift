//
//  FirestoreManager.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Protocols

/// Protocol for Firestore operations
protocol FirestoreServiceProtocol {
    func addDocument<T: Codable>(to collection: String, object: T) async throws
    func updateDocument<T: Codable>(in collection: String, documentId: String, object: T) async throws
    func deleteDocument(from collection: String, documentId: String) async throws
    func fetchDocument<T: Codable>(from collection: String, documentId: String, as type: T.Type) async throws -> T?
    func queryDocuments<T: Codable>(from collection: String, where field: String, isEqualTo value: Any, as type: T.Type) async throws -> [T]
}

/// Protocol for data models that can be saved to Firestore
protocol FirestoreDocument: Codable {
    var id: String? { get set }
    var userId: String { get }
    var createdAt: Date { get }
}

/// Protocol for data models that represent user history
protocol UserHistoryDocument: FirestoreDocument {
    var createdAt: Date { get }
}

/// FirestoreManager is a generic manager for Firestore operations in SwiftUI.
/// It supports CRUD operations for any Codable model, and is compatible with Dependency Injection and EnvironmentObject.
/// Use this manager for adding, fetching, updating, deleting, and querying documents in Firestore.
final class FirestoreManager: ObservableObject, FirestoreServiceProtocol {
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Public initializer for Dependency Injection
    init() {}
    
    // MARK: - Add Document
    
    /**
     Adds a new document to the specified Firestore collection (async version).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - object: Codable object to be saved.
     - Throws: AppError if the operation fails.
     
     Example:
     ```
     try await firestoreManager.addDocument(to: "users", object: newUser)
     ```
     */
    func addDocument<T: Codable>(to collection: String, object: T) async throws {
        do {
            _ = try await db.collection(collection).addDocument(from: object, encoder: Firestore.Encoder())
        } catch let error as NSError {
            throw AppError.firestoreError(.writeFailed(error.localizedDescription))
        }
    }
    
    /**
     Adds a new document to the specified Firestore collection (completion handler version - deprecated).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - object: Codable object to be saved.
        - completion: Optional completion handler returning an Error if any.
     
     Example:
     ```
     FirestoreManager.shared.addDocument(to: "users", object: newUser) { error in
         if let error = error { print(error) }
     }
     ```
     */
    @available(*, deprecated, message: "Use async version instead")
    func addDocument<T: Codable>(to collection: String, object: T, completion: ((AppError?) -> Void)? = nil) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.addDocument(to: collection, object: object)
                completion?(nil)
            } catch {
                completion?(error as? AppError)
            }
        }
    }
    
    // MARK: - Update Document
    
    /**
     Updates an existing document in the specified collection (async version).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to update.
        - object: Codable object containing updated data.
     - Throws: AppError if the operation fails.
     */
    func updateDocument<T: Codable>(in collection: String, documentId: String, object: T) async throws {
        do {
            try await db.collection(collection).document(documentId).setData(from: object, merge: true)
        } catch let error as NSError {
            throw AppError.firestoreError(.writeFailed(error.localizedDescription))
        }
    }
    
    /**
     Updates an existing document in the specified collection (completion handler version - deprecated).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to update.
        - object: Codable object containing updated data.
        - completion: Optional completion handler returning an Error if any.
     */
    @available(*, deprecated, message: "Use async version instead")
    func updateDocument<T: Codable>(collection: String, documentId: String, object: T, completion: ((AppError?) -> Void)? = nil) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.updateDocument(in: collection, documentId: documentId, object: object)
                completion?(nil)
            } catch {
                completion?(error as? AppError)
            }
        }
    }
    
    // MARK: - Delete Document
    
    /**
     Deletes a document from the specified collection (async version).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to delete.
     - Throws: AppError if the operation fails.
     */
    func deleteDocument(from collection: String, documentId: String) async throws {
        do {
            try await db.collection(collection).document(documentId).delete()
        } catch {
            throw AppError.firestoreError(.unknown)
        }
    }
    
    /**
     Deletes a document from the specified collection (completion handler version - deprecated).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to delete.
        - completion: Optional completion handler returning an Error if any.
     */
    @available(*, deprecated, message: "Use async version instead")
    func deleteDocument(collection: String, documentId: String, completion: ((AppError?) -> Void)? = nil) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.deleteDocument(from: collection, documentId: documentId)
                completion?(nil)
            } catch {
                completion?(error as? AppError)
            }
        }
    }
    
    /**
     Deletes all user data from all collections (async version).
     
     - Parameter userId: The user ID whose data should be deleted.
     - Throws: AppError if the operation fails.
     */
    func deleteUserData(userId: String) async throws {
        let collections = ["departmentSuggestions", "diseasePredictions", "homeSolutions", "labResultRecommendations", "naturalSolutions"]
        
        for collection in collections {
            let query = db.collection(collection).whereField("userId", isEqualTo: userId)
            let snapshot = try await query.getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
        }
    }
    
    // MARK: - Fetch Single Document
    
    /**
     Fetches a single document from the specified collection (async version).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to fetch.
     - Returns: The decoded object or nil if not found.
     - Throws: AppError if the operation fails.
     */
    func fetchDocument<T: Codable>(from collection: String, documentId: String, as type: T.Type) async throws -> T? {
        do {
            let snapshot = try await db.collection(collection).document(documentId).getDocument()
            
            guard snapshot.exists else {
                throw AppError.firestoreError(.documentNotFound("Document with ID \(documentId) not found."))
            }
            
            return try snapshot.data(as: T.self)
        } catch let error as NSError {
            if error.domain == "FIRFirestoreErrorDomain" && error.code == 5 {
                // Document not found
                return nil
            }
            throw AppError.firestoreError(.readFailed(error.localizedDescription))
        }
    }
    
    /**
     Fetches a single document from the specified collection (completion handler version - deprecated).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to fetch.
        - completion: Completion handler returning the decoded object or nil.
     */
    @available(*, deprecated, message: "Use async version instead")
    func fetchDocument<T: Codable>(collection: String, documentId: String, completion: @escaping (Result<T?, AppError>) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let result: T? = try await fetchDocument(from: collection, documentId: documentId, as: T.self)
                completion(.success(result))
            } catch {
                completion(.failure(error as? AppError ?? AppError.firestoreError(.unknown)))
            }
        }
    }
    
    // MARK: - Fetch All Documents
    
    /**
     Fetches all documents from a collection.
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - completion: Completion handler returning an array of decoded objects.
     */
    func fetchAllDocuments<T: Codable>(collection: String, completion: @escaping (Result<[T], AppError>) -> Void) {
        db.collection(collection).getDocuments { snapshot, error in
            if let firestoreError = error as NSError? {
                completion(.failure(.firestoreError(.readFailed(firestoreError.localizedDescription))))
                return
            }
            guard let documents = snapshot?.documents else {
                completion(.failure(.firestoreError(.unknown)))
                return
            }
            let objects: [T] = documents.compactMap { doc in
                try? doc.data(as: T.self)
            }
            completion(.success(objects))
        }
    }
    
    // MARK: - Query Documents with where clause
    
    /**
     Queries documents in a collection with a whereField condition (async version).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - field: Field name to filter by.
        - value: Value to match.
     - Returns: An array of decoded objects.
     - Throws: AppError if the operation fails.
     
     Example:
     ```
     let logs: [SymptomLog] = try await firestoreManager.queryDocuments(collection: "symptomsLogs", field: "userId", isEqualTo: "abc123")
     ```
     */
    func queryDocuments<T: Codable>(from collection: String, where field: String, isEqualTo value: Any, as type: T.Type) async throws -> [T] {
        do {
            let snapshot = try await db.collection(collection).whereField(field, isEqualTo: value).getDocuments()
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: T.self)
            }
        } catch let error as NSError {
            throw AppError.firestoreError(.readFailed(error.localizedDescription))
        }
    }
    
    /**
     Queries documents in a collection with a whereField condition (completion handler version - deprecated).
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - field: Field name to filter by.
        - value: Value to match.
        - completion: Completion handler returning an array of decoded objects.
     
     Example:
     ```
     FirestoreManager.shared.queryDocuments(collection: "symptomsLogs", field: "userId", isEqualTo: "abc123") { (logs: [SymptomLog]) in
         print(logs)
     }
     ```
     */
    @available(*, deprecated, message: "Use async version instead")
    func queryDocuments<T: Codable>(collection: String, field: String, isEqualTo value: Any, completion: @escaping (Result<[T], AppError>) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let result: [T] = try await queryDocuments(from: collection, where: field, isEqualTo: value, as: T.self)
                completion(.success(result))
            } catch {
                completion(.failure(error as? AppError ?? AppError.firestoreError(.unknown)))
            }
        }
    }
    
    // MARK: - Listen to Collection Changes (Realtime Updates)
    
    /**
     Listens for real-time updates in a collection.
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - completion: Completion handler returning updated array of decoded objects whenever the collection changes.
     
     Example:
     ```
     FirestoreManager.shared.listenToCollection(collection: "users") { (users: [UserModel]) in
         print(users)
     }
     ```
     */
    func listenToCollection<T: Codable>(collection: String, completion: @escaping (Result<[T], AppError>) -> Void) -> ListenerRegistration {
        let listener = db.collection(collection).addSnapshotListener { snapshot, error in
            if let firestoreError = error as NSError? {
                completion(.failure(.firestoreError(.networkError(firestoreError.localizedDescription))))
                return
            }
            guard let documents = snapshot?.documents else {
                completion(.failure(.firestoreError(.unknown)))
                return
            }
            let objects: [T] = documents.compactMap { doc in
                try? doc.data(as: T.self)
            }
            completion(.success(objects))
        }
        return listener
    }
}
