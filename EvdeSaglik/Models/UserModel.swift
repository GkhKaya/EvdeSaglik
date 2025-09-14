//
//  UserModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore

// User model – stores the profile information of the user
struct UserModelModel: Identifiable, Codable {
    @DocumentID var id: String?
    var fullName: String        // User's full name
    var email: String           // Email address
    var age: Int                // Age
    var gender: String          // Gender
    var chronicDiseases: [String]  // List of chronic diseases
    var allergies: [String]        // List of allergies
    var lifestyle: String          // Lifestyle description (e.g., sedentary, active)
    var profileImageUrl: String?   // Profile picture URL
    var createdAt: Date            // Account creation timestamp
}
