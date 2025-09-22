import Foundation
import SwiftUI

final class DrugFoodInteractionViewModel: BaseViewModel {
    @Published var drugName = ""
    @Published var foodName = ""
    @Published var isSaving = false
    @Published var interactionResult = ""
    @Published var showSaveAlert = false
    @Published var saveSuccess = false
    
    private let userManager: UserManager
    private let firestoreManager: FirestoreManager
    private let authManager: FirebaseAuthManager
    
    init(userManager: UserManager, firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self.userManager = userManager
        self.firestoreManager = firestoreManager
        self.authManager = authManager
    }
    
    func checkInteraction() {
        // ✅ YENİ: Standardized validation using ValidationHelper
        guard validateDrugFoodForm(drugName: drugName, foodName: foodName) else {
            return // Error already handled by BaseViewModel
        }
        
        isLoading = true
        errorMessage = nil
        interactionResult = ""
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let userSummary = userManager.generateUserSummaryPrompt()
                let systemPersona = NSLocalizedString("DrugFoodInteraction.SystemPersona", comment: "")
                let systemFormat = NSLocalizedString("DrugFoodInteraction.SystemFormat", comment: "")
                let userPrompt = String(format: NSLocalizedString("DrugFoodInteraction.UserPrompt", comment: ""), drugName, foodName, userSummary)
                
                let messages = [
                    DeepseekMessage(role: "system", content: "\(systemPersona)\n\n\(systemFormat)"),
                    DeepseekMessage(role: "user", content: userPrompt)
                ]
                
                let result = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messages)
                
                await MainActor.run {
                    self.interactionResult = self.cleanMarkdownText(result)
                    self.isLoading = false
                }
            } catch {
                // ✅ YENİ: Standardized error handling
                await MainActor.run {
                    self.handleError(error, context: "DrugFoodInteraction")
                }
            }
        }
    }
    
    func saveToHistory() {
        guard let userId = authManager.currentUser?.uid else {
            // ✅ YENİ: Use standardized error handling
            handleError(AppError.businessLogicError(.userNotFound), context: "DrugFoodInteraction.Save")
            return
        }
        
        isSaving = true
        
        let userSummary = userManager.generateUserSummaryPrompt()
        let interactionModel = DrugFoodInteractionModel(
            userId: userId,
            drugName: drugName,
            foodName: foodName,
            interactionResult: interactionResult,
            userSummary: userSummary
        )
        
        // ✅ YENİ: Use async/await instead of completion handler
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await firestoreManager.addDocument(to: "drugFoodInteractions", object: interactionModel)
                await MainActor.run {
                    self.isSaving = false
                    self.saveSuccess = true
                    self.handleSuccess(NSLocalizedString("DrugFoodInteraction.SaveSuccess", comment: "Successfully saved to history"))
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.handleError(error, context: "DrugFoodInteraction.Save")
                }
            }
        }
    }
    
    func resetForm() {
        drugName = ""
        foodName = ""
        interactionResult = ""
        clearMessages() // ✅ YENİ: Use BaseViewModel method
        saveSuccess = false
        isSaving = false
    }
    
    private func cleanMarkdownText(_ text: String) -> String {
        var cleanedText = text
        
        // Remove markdown headers (# ## ### #### ##### ######)
        cleanedText = cleanedText.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        
        // Remove bold/italic markdown (**text** or *text*)
        cleanedText = cleanedText.replacingOccurrences(of: #"\*{1,2}([^*]+)\*{1,2}"#, with: "$1", options: .regularExpression)
        
        // Remove markdown links [text](url)
        cleanedText = cleanedText.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        
        // Remove markdown lists (- item or * item) and replace with bullet points
        cleanedText = cleanedText.replacingOccurrences(of: #"^[\s]*[-*]\s+"#, with: "• ", options: .regularExpression)
        
        // Remove markdown code blocks ```
        cleanedText = cleanedText.replacingOccurrences(of: #"```[^`]*```"#, with: "", options: .regularExpression)
        
        // Remove inline code `code`
        cleanedText = cleanedText.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        
        // Remove any remaining # symbols that might be standalone
        cleanedText = cleanedText.replacingOccurrences(of: #"#+"#, with: "", options: .regularExpression)
        
        // Clean up extra whitespace and newlines
        cleanedText = cleanedText.replacingOccurrences(of: #"\n\s*\n\s*\n"#, with: "\n\n", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: #"\n\s*\n"#, with: "\n\n", options: .regularExpression)
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
}