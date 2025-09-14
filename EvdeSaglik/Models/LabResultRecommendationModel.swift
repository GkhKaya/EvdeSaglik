//
//  LabResultRecommendation.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore

struct LabResultRecommendationModel: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var labResults: [String: Double] // Test adı: değer
    var suggestedMedications: [String]
    var suggestedNaturalSolutions: [String]
    var createdAt: Date
}
