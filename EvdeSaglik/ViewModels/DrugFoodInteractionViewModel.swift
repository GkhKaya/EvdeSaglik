import Foundation
import SwiftUI

final class DrugFoodInteractionViewModel: ObservableObject {
    @Published var drugName = ""
    @Published var foodName = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var interactionResult = ""
    @Published var errorMessage: AppError? = nil
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
        guard !drugName.isEmpty && !foodName.isEmpty else {
            errorMessage = .authError(.loginFailed(NSLocalizedString("DrugFoodInteraction.EmptyFields", comment: "Lütfen hem ilaç hem de gıda adını giriniz.")))
            return
        }
        
        isLoading = true
        errorMessage = nil
        interactionResult = ""
        
        Task {
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
                await MainActor.run {
                    self.errorMessage = error as? AppError ?? .authError(.unknown)
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveToHistory() {
        guard let userId = authManager.currentUser?.uid else {
            errorMessage = .authError(.unknown)
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
        
        firestoreManager.addDocument(to: "drugFoodInteractions", object: interactionModel) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    self.errorMessage = error
                } else {
                    self.saveSuccess = true
                }
            }
        }
    }
    
    func resetForm() {
        drugName = ""
        foodName = ""
        interactionResult = ""
        errorMessage = nil
        saveSuccess = false
        isSaving = false
    }
    
    private func cleanMarkdownText(_ text: String) -> String {
        var cleanedText = text
        
        // Remove markdown headers (# ## ###)
        cleanedText = cleanedText.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        
        // Remove bold/italic markdown (**text** or *text*)
        cleanedText = cleanedText.replacingOccurrences(of: #"\*{1,2}([^*]+)\*{1,2}"#, with: "$1", options: .regularExpression)
        
        // Remove markdown links [text](url)
        cleanedText = cleanedText.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        
        // Remove markdown lists (- item or * item)
        cleanedText = cleanedText.replacingOccurrences(of: #"^[\s]*[-*]\s+"#, with: "• ", options: .regularExpression)
        
        // Remove markdown code blocks ```
        cleanedText = cleanedText.replacingOccurrences(of: #"```[^`]*```"#, with: "", options: .regularExpression)
        
        // Remove inline code `code`
        cleanedText = cleanedText.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        
        // Clean up extra whitespace
        cleanedText = cleanedText.replacingOccurrences(of: #"\n\s*\n"#, with: "\n\n", options: .regularExpression)
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
}
