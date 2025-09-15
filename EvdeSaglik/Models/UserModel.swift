//
//  UserModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import Foundation
import FirebaseFirestore

// User model – stores the profile information of the user
struct UserModel: Identifiable, Codable {
    @DocumentID var id: String?
    var fullName: String           // User's full name
    var email: String              // Email address
    var age: Int                   // Age
    var gender: String             // Gender (Male/Female/Other)
    var chronicDiseases: [String]  // List of chronic diseases
    var allergies: [String]        // List of allergies
    var medications: [String]      // Regular medications
    var sleepPattern: String       // Sleep pattern (Good/Average/Poor)
    var physicalActivity: String   // Physical activity level (Low/Moderate/High)
    var nutritionHabits: String    // Nutrition habits (Poor/Average/Good)
    var profileImageUrl: String?   // Profile picture URL
    var isOnboardingCompleted: Bool // Whether user completed onboarding
    var createdAt: Date            // Account creation timestamp
    
    init(
        fullName: String = "",
        email: String = "",
        age: Int = 0,
        gender: String = "",
        chronicDiseases: [String] = [],
        allergies: [String] = [],
        medications: [String] = [],
        sleepPattern: String = "",
        physicalActivity: String = "",
        nutritionHabits: String = "",
        profileImageUrl: String? = nil,
        isOnboardingCompleted: Bool = false
    ) {
        self.fullName = fullName
        self.email = email
        self.age = age
        self.gender = gender
        self.chronicDiseases = chronicDiseases
        self.allergies = allergies
        self.medications = medications
        self.sleepPattern = sleepPattern
        self.physicalActivity = physicalActivity
        self.nutritionHabits = nutritionHabits
        self.profileImageUrl = profileImageUrl
        self.isOnboardingCompleted = isOnboardingCompleted
        self.createdAt = Date()
    }
}
