//
//  HomeSolutionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

final class HomeSolutionViewViewModel: BaseViewModel {
    @Published var inputText: String = ""
    @Published var resultText: String = ""
    @Published var isSaving: Bool = false
    @Published var saveMessage: String? = nil

    func buildPrompt(userSummary: String) -> [DeepseekMessage] {
        let system = [
            NSLocalizedString("HomeSolution.SystemPersona", comment: ""),
            userSummary,
            NSLocalizedString("HomeSolution.SystemFormat", comment: "")
        ].joined(separator: "\n\n")

        let user = inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? NSLocalizedString("HomeSolution.DefaultUserPrompt", comment: "")
        : String(format: NSLocalizedString("HomeSolution.UserPrompt", comment: ""), inputText)

        return [
            DeepseekMessage(role: "system", content: system),
            DeepseekMessage(role: "user", content: user)
        ]
    }

    @MainActor
    func requestHomeSolutions(userSummary: String) async {
        performAsyncOperation(
            operation: {
                let messages = self.buildPrompt(userSummary: userSummary)
                let response = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messages)
                // Clean markdown formatting more thoroughly
                let cleaned = self.cleanMarkdownText(response)
                return cleaned
            },
            context: "HomeSolutionViewViewModel.requestHomeSolutions",
            onSuccess: { [weak self] result in
                self?.resultText = result
            }
        )
    }

    // MARK: - Persist
    @MainActor
    func saveSolution(userId: String, firestoreManager: FirestoreManager) {
        guard !resultText.isEmpty else { return }
        
        performAsyncOperation(
            operation: {
                let model = HomeSolutionModel(
                    id: nil,
                    userId: userId,
                    symptom: self.inputText.trimmingCharacters(in: .whitespacesAndNewlines),
                    solutions: [Solution(title: "Home Solution", description: self.resultText)],
                    createdAt: Date()
                )
                
                try await firestoreManager.addDocument(to: "homeSolutions", object: model)
                return true
            },
            context: "HomeSolutionViewViewModel.saveSolution",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("HomeSolution.SaveSuccess", comment: ""))
            }
        )
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

//
//  HomeSolutionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
