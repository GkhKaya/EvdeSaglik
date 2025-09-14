//
//  DepartmentSuggestion.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore


// Stores AI suggestions for which medical department a user should visit
struct DepartmentSuggestionModel: Identifiable, Codable {
    @DocumentID var id: String?                     // Auto-generated Firestore ID
    var userId: String                              // Reference to the user
    var symptoms: [String]                          // List of symptoms entered by the user
    var suggestedDepartments: [String]             // AI-suggested medical departments
    var createdAt: Date                             // Timestamp
}
