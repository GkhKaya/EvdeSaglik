//
//  DiseasePrediction.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore

struct DiseasePredictionModel: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var symptoms: [String]
    var possibleDiseases: [PredictedDisease]
    var createdAt: Date
}

struct PredictedDisease: Codable {
    var name: String
    var probability: Double
}
