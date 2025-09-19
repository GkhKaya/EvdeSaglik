//
//  InteractiveIntroductionViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine
import SwiftUI

final class InteractiveIntroductionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: Int = 1
    @Published var userModel: UserModel = UserModel()
    @Published var isLoading: Bool = false
    @Published var shouldNavigateToMain: Bool = false
    
    // Dependencies
    private let firestoreManager: FirestoreManager
    private let authManager: FirebaseAuthManager
    
    // Step-specific properties
    @Published var selectedGender: String = ""
    @Published var selectedAge: String = ""
    @Published var selectedChronicDiseases: [String] = []
    @Published var selectedAllergies: [String] = []
    @Published var selectedMedications: [String] = []
    @Published var selectedSleepPattern: String = ""
    @Published var selectedPhysicalActivity: String = ""
    @Published var selectedNutritionHabits: String = ""
    
    // MARK: - Constants
    let totalSteps = 5
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager, isFromProfile: Bool = false) {
        self.firestoreManager = firestoreManager
        self.authManager = authManager
        
        // Start from step 2 if coming from profile (skip introduction)
        if isFromProfile {
            self.currentStep = 2
        }
        
        loadExistingUserData()
    }
    
    // MARK: - Load Existing User Data
    private func loadExistingUserData() {
        guard let userId = authManager.currentUser?.uid else { return }
        
        firestoreManager.fetchDocument(collection: "users", documentId: userId) { [weak self] (result: Result<UserModel?, AppError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let userModel):
                    if let userModel = userModel {
                        self?.populateFieldsWithExistingData(userModel)
                    }
                case .failure(let error):
                    print("Failed to load user data: \(error)")
                }
            }
        }
    }
    
    private func populateFieldsWithExistingData(_ userModel: UserModel) {
        self.userModel = userModel
        
        // Populate step-specific fields
        selectedGender = userModel.gender
        selectedAge = userModel.age > 0 ? "\(userModel.age)" : ""
        selectedChronicDiseases = userModel.chronicDiseases
        selectedAllergies = userModel.allergies
        selectedMedications = userModel.medications
        selectedSleepPattern = userModel.sleepPattern
        selectedPhysicalActivity = userModel.physicalActivity
        selectedNutritionHabits = userModel.nutritionHabits
    }
    
    // MARK: - Computed Properties
    var canProceed: Bool {
        switch currentStep {
        case 1:
            return true // Can always skip introduction
        case 2:
            return !userModel.fullName.isEmpty && !selectedGender.isEmpty && !selectedAge.isEmpty
        case 3:
            return true // Optional selections
        case 4:
            return !selectedSleepPattern.isEmpty && !selectedPhysicalActivity.isEmpty && !selectedNutritionHabits.isEmpty
        case 5:
            return true // Summary step
        default:
            return false
        }
    }
    
    // MARK: - Public Methods
    func nextStep() {
        updateUserModel()
        
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    func skipOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Instead of just going to the last step, directly finish onboarding
            finishOnboarding(firestoreManager: firestoreManager, authManager: authManager)
        }
    }
    
    func finishOnboarding(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        updateUserModel()
        userModel.isOnboardingCompleted = true
        userModel.isInformationHas = true // Set the new flag here
        
        isLoading = true
        
        guard let userId = authManager.currentUser?.uid, let userEmail = authManager.currentUser?.email else {
            print("Error: User not authenticated or email not available. Cannot save onboarding data.")
            isLoading = false
            return
        }
        
        userModel.id = userId // Ensure the userModel has the correct Firestore document ID
        userModel.email = userEmail // Set the email from the authenticated user
        
        // Save user data to Firestore
        firestoreManager.updateDocument(collection: "users", documentId: userId, object: userModel) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if error == nil {
                    self?.shouldNavigateToMain = true
                    // Reset didJustRegister flag after successful onboarding
                    self?.authManager.didJustRegister = false
                }
            }
        }
    }
    
    // MARK: - Update Profile Data
    func updateProfileData() {
        updateUserModel()
        
        isLoading = true
        
        guard let userId = authManager.currentUser?.uid, let userEmail = authManager.currentUser?.email else {
            print("Error: User not authenticated or email not available. Cannot save profile data.")
            isLoading = false
            return
        }
        
        userModel.id = userId
        userModel.email = userEmail
        
        // Save updated user data to Firestore
        firestoreManager.updateDocument(collection: "users", documentId: userId, object: userModel) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if error == nil {
                    self?.shouldNavigateToMain = true
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateUserModel() {
        switch currentStep {
        case 2:
            userModel.gender = selectedGender
            if let age = Int(selectedAge) {
                userModel.age = age
            }
        case 3:
            userModel.chronicDiseases = selectedChronicDiseases
            userModel.allergies = selectedAllergies
            userModel.medications = selectedMedications
        case 4:
            userModel.sleepPattern = selectedSleepPattern
            userModel.physicalActivity = selectedPhysicalActivity
            userModel.nutritionHabits = selectedNutritionHabits
        default:
            break
        }
    }
}
