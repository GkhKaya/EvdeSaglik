//
//  HomeSolutionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

final class HomeSolutionViewViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
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
        errorMessage = nil
        resultText = ""
        isLoading = true
        defer { isLoading = false }

        let messages = buildPrompt(userSummary: userSummary)
        do {
            let response = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messages)
            // Clean markdown formatting
            let cleaned = response
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "###", with: "")
                .replacingOccurrences(of: "##", with: "")
                .replacingOccurrences(of: "#", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            self.resultText = cleaned
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Persist
    @MainActor
    func saveSolution(userId: String, firestoreManager: FirestoreManager) {
        guard !resultText.isEmpty else { return }
        
        isSaving = true
        saveMessage = nil
        
        let model = HomeSolutionModel(
            id: nil,
            userId: userId,
            symptom: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
            solutions: [Solution(title: "Home Solution", description: resultText)],
            createdAt: Date()
        )
        
        firestoreManager.addDocument(to: "homeSolutions", object: model) { [weak self] err in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let err = err {
                    self?.saveMessage = NSLocalizedString("HomeSolution.SaveError", comment: "")
                    print("Firestore save error: \(err)")
                } else {
                    self?.saveMessage = NSLocalizedString("HomeSolution.SaveSuccess", comment: "")
                    // Clear message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.saveMessage = nil
                    }
                }
            }
        }
    }
}

//
//  HomeSolutionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
