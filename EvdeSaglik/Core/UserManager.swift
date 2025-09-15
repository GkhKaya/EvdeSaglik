import Foundation
import SwiftUI // For @EnvironmentObject

// MARK: - UserManager
/// UserManager provides functionalities related to managing user data,
/// specifically for generating AI prompt strings based on UserModel.
final class UserManager: ObservableObject {
    
    @Published var currentUserModel: UserModel? = nil
    
    var firestoreManager: FirestoreManager! // Change to var, implicitly unwrapped optional
    var authManager: FirebaseAuthManager!   // Change to var, implicitly unwrapped optional
    
    init() { /* Default initializer */ }
    
    func setup(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self.firestoreManager = firestoreManager
        self.authManager = authManager
        fetchCurrentUserModel()
    }
    
    /// Fetches the current user's UserModel from Firestore.
    func fetchCurrentUserModel() {
        guard let userId = authManager.currentUser?.uid else {
            print("Error: User not authenticated. Cannot fetch user model.")
            return
        }
        
        firestoreManager.fetchDocument(collection: "users", documentId: userId) { [weak self] (result: Result<UserModel?, AppError>) in
            switch result {
            case .success(let userModel):
                self?.currentUserModel = userModel
            case .failure(let error):
                print("Error fetching user model: \(error.localizedDescription)")
                self?.currentUserModel = nil
            }
        }
    }
    
    /// Generates a detailed user summary as a prompt string for AI.
    /// This includes personal, health, and lifestyle information, localized.
    func generateUserSummaryPrompt() -> String {
        guard let user = currentUserModel else {
            return NSLocalizedString("UserManager.NoUserInformation", comment: "No user information available.")
        }
        
        var summary: [String] = []
        
        // Basic Information
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.FullName", comment: ""), user.fullName))
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.Age", comment: ""), user.age))
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.Gender", comment: ""), user.gender))
        
        // Health Status
        let chronicDiseases = user.chronicDiseases.isEmpty ? NSLocalizedString("Onboarding.HealthInfo.ChronicDiseases.None", comment: "") : user.chronicDiseases.joined(separator: ", ")
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.ChronicDiseases", comment: ""), chronicDiseases))
        
        let allergies = user.allergies.isEmpty ? NSLocalizedString("Onboarding.HealthInfo.Allergies.None", comment: "") : user.allergies.joined(separator: ", ")
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.Allergies", comment: ""), allergies))
        
        let medications = user.medications.isEmpty ? NSLocalizedString("Onboarding.HealthInfo.Medications.None", comment: "") : user.medications.joined(separator: ", ")
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.Medications", comment: ""), medications))
        
        // Lifestyle
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.SleepPattern", comment: ""), user.sleepPattern))
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.PhysicalActivity", comment: ""), user.physicalActivity))
        summary.append(String(format: NSLocalizedString("UserManager.Prompt.NutritionHabits", comment: ""), user.nutritionHabits))
        
        return summary.joined(separator: "\n")
    }
}
