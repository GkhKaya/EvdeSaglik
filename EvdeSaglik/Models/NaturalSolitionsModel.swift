//
//  NaturalSolitions.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore

struct NaturalSolitionsModel: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var question: String
    var remedies: [String]
    var createdAt: Date
}
