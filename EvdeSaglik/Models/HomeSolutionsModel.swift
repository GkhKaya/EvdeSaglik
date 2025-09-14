//
//  HomeSolutions.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore

struct HomeSolutionModel: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var symptom: String
    var solutions: [Solution]
    var createdAt: Date
}

struct Solution: Codable {
    var title: String
    var description: String
}
