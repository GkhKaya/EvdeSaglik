//
//  InteractiveIntroductionViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import Combine
import SwiftUI

final class InteractiveIntroductionViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var currentStep: Int = 1
    @Published var userModel: UserModel = UserModel()
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
    let totalSteps = 6
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager, isFromProfile: Bool = false) {
        self.firestoreManager = firestoreManager
        self.authManager = authManager
        
        super.init()
        
        // Start from step 2 if coming from profile (skip introduction)
        if isFromProfile {
            self.currentStep = 2
        }
        
        loadExistingUserData()
    }
    
    // MARK: - Load Existing User Data
    private func loadExistingUserData() {
        guard let userId = authManager.currentUser?.uid else { return }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let userModel: UserModel? = try await firestoreManager.fetchDocument(from: "users", documentId: userId, as: UserModel.self)
                await MainActor.run {
                    if let userModel = userModel {
                        self.populateFieldsWithExistingData(userModel)
                    }
                }
            } catch {
                print("Failed to load user data: \(error)")
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
            return true // Welcome step - always can proceed
        case 4:
            return true // Optional selections
        case 5:
            return !selectedSleepPattern.isEmpty && !selectedPhysicalActivity.isEmpty && !selectedNutritionHabits.isEmpty
        case 6:
            return true // Summary step
        default:
            return false
        }
    }
    
    // MARK: - Public Methods
    func nextStep() {
        // Always update user model before proceeding
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
        // Ensure all data is updated before saving
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
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                print("💾 Saving user data to Firestore:")
                print("   - User ID: \(userId)")
                print("   - Email: \(userEmail)")
                print("   - Full Name: \(userModel.fullName)")
                print("   - Gender: \(userModel.gender)")
                print("   - Age: \(userModel.age)")
                
                try await firestoreManager.updateDocument(in: "users", documentId: userId, object: userModel)
                
                print("✅ User data saved successfully to Firestore!")
                
                await MainActor.run {
                    self.isLoading = false
                    self.shouldNavigateToMain = true
                    // Reset didJustRegister flag after successful onboarding
                    self.authManager.didJustRegister = false
                }
            } catch {
                print("❌ Error saving user data to Firestore: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Update Profile Data
    func updateProfileData() {
        // Ensure all data is updated before saving
        updateUserModel()
        
        isLoading = true
        
        guard let userId = authManager.currentUser?.uid, let userEmail = authManager.currentUser?.email else {
            print("Error: User not authenticated or email not available. Cannot save profile data.")
            isLoading = false
            return
        }
        
        userModel.id = userId
        userModel.email = userEmail
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await firestoreManager.updateDocument(in: "users", documentId: userId, object: userModel)
                await MainActor.run {
                    self.isLoading = false
                    self.shouldNavigateToMain = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateUserModel() {
        // Always update basic info (step 2)
        userModel.gender = selectedGender
        if let age = Int(selectedAge) {
            userModel.age = age
        }
        
        // Update health info (step 4)
        userModel.chronicDiseases = selectedChronicDiseases
        userModel.allergies = selectedAllergies
        userModel.medications = selectedMedications
        
        // Update lifestyle info (step 5)
        userModel.sleepPattern = selectedSleepPattern
        userModel.physicalActivity = selectedPhysicalActivity
        userModel.nutritionHabits = selectedNutritionHabits
        
        // Debug: Print current user model data
        print("🔍 UserModel updated:")
        print("   - Full Name: \(userModel.fullName)")
        print("   - Gender: \(userModel.gender)")
        print("   - Age: \(userModel.age)")
        print("   - Chronic Diseases: \(userModel.chronicDiseases)")
        print("   - Allergies: \(userModel.allergies)")
        print("   - Medications: \(userModel.medications)")
        print("   - Sleep Pattern: \(userModel.sleepPattern)")
        print("   - Physical Activity: \(userModel.physicalActivity)")
        print("   - Nutrition Habits: \(userModel.nutritionHabits)")
    }
}
