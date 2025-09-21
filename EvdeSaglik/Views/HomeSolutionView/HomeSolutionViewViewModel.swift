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
                // Clean markdown formatting
                let cleaned = response
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .replacingOccurrences(of: "###", with: "")
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
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
}

//
//  HomeSolutionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
