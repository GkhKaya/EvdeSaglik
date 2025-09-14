//
//  FirestoreManager.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation

import FirebaseFirestore


/// FirestoreManager is a generic manager for Firestore operations in SwiftUI.
/// It supports CRUD operations for any Codable model, and is compatible with Dependency Injection and EnvironmentObject.
/// Use this manager for adding, fetching, updating, deleting, and querying documents in Firestore.
final class FirestoreManager: ObservableObject {
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Public initializer for Dependency Injection
    init() {}
    
    // MARK: - Add Document
    
    /**
     Adds a new document to the specified Firestore collection.
     
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
    func addDocument<T: Codable>(to collection: String, object: T, completion: ((AppError?) -> Void)? = nil) {
        do {
            _ = try db.collection(collection).addDocument(from: object, encoder: Firestore.Encoder()) { error in
                if let firestoreError = error as NSError? {
                    completion?(.firestoreError(.writeFailed(firestoreError.localizedDescription)))
                } else {
                    completion?(nil)
                }
            }
        } catch let encodeError as NSError {
            completion?(.firestoreError(.writeFailed(encodeError.localizedDescription)))
        }
    }
    
    // MARK: - Update Document
    
    /**
     Updates an existing document in the specified collection.
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to update.
        - object: Codable object containing updated data.
        - completion: Optional completion handler returning an Error if any.
     */
    func updateDocument<T: Codable>(collection: String, documentId: String, object: T, completion: ((AppError?) -> Void)? = nil) {
        do {
            try db.collection(collection).document(documentId).setData(from: object, merge: true) { error in
                if let firestoreError = error as NSError? {
                    completion?(.firestoreError(.writeFailed(firestoreError.localizedDescription)))
                } else {
                    completion?(nil)
                }
            }
        } catch let encodeError as NSError {
            completion?(.firestoreError(.writeFailed(encodeError.localizedDescription)))
        }
    }
    
    // MARK: - Delete Document
    
    /**
     Deletes a document from the specified collection.
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to delete.
        - completion: Optional completion handler returning an Error if any.
     */
    func deleteDocument(collection: String, documentId: String, completion: ((AppError?) -> Void)? = nil) {
        db.collection(collection).document(documentId).delete { error in
            if error != nil {
                completion?(.firestoreError(.unknown))
            } else {
                completion?(nil)
            }
        }
    }
    
    // MARK: - Fetch Single Document
    
    /**
     Fetches a single document from the specified collection.
     
     - Parameters:
        - collection: Name of the Firestore collection.
        - documentId: ID of the document to fetch.
        - completion: Completion handler returning the decoded object or nil.
     */
    func fetchDocument<T: Codable>(collection: String, documentId: String, completion: @escaping (Result<T?, AppError>) -> Void) {
        db.collection(collection).document(documentId).getDocument { snapshot, error in
            if let firestoreError = error as NSError? {
                completion(.failure(.firestoreError(.readFailed(firestoreError.localizedDescription))))
                return
            }
            guard let snapshot = snapshot else {
                completion(.failure(.firestoreError(.unknown)))
                return
            }
            guard snapshot.exists else {
                completion(.failure(.firestoreError(.documentNotFound("Document with ID \(documentId) not found."))))
                return
            }
            do {
                let object = try snapshot.data(as: T.self)
                completion(.success(object))
            } catch let decodeError as NSError {
                print("Firestore decode error: \(decodeError)")
                completion(.failure(.firestoreError(.readFailed(decodeError.localizedDescription))))
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
     Queries documents in a collection with a whereField condition.
     
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
    func queryDocuments<T: Codable>(collection: String, field: String, isEqualTo value: Any, completion: @escaping (Result<[T], AppError>) -> Void) {
        db.collection(collection).whereField(field, isEqualTo: value).getDocuments { snapshot, error in
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
