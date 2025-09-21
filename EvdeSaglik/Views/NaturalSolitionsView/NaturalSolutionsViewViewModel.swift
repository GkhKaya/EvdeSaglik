//
//  NaturalSolutionsViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

final class NaturalSolutionsViewViewModel: BaseViewModel {
    @Published var predefinedConcerns: [String] = [
        NSLocalizedString("NaturalSolutions.Concern.Headache", comment: ""),
        NSLocalizedString("NaturalSolutions.Concern.Insomnia", comment: ""),
        NSLocalizedString("NaturalSolutions.Concern.Digestive", comment: ""),
        NSLocalizedString("NaturalSolutions.Concern.Stress", comment: ""),
        NSLocalizedString("NaturalSolutions.Concern.Cold", comment: ""),
        NSLocalizedString("NaturalSolutions.Concern.Fatigue", comment: ""),
        NSLocalizedString("NaturalSolutions.Concern.Skin", comment: ""),
        NSLocalizedString("NaturalSolutions.Concern.JointPain", comment: "")
    ]
    @Published var selectedConcerns: Set<String> = []
    @Published var includeOther: Bool = false
    @Published var otherConcernsText: String = ""
    @Published var feelingsText: String = ""

    @Published var resultText: String = ""
    @Published var isSaving: Bool = false
    @Published var saveMessage: String? = nil

    func toggleConcern(_ concern: String) {
        if selectedConcerns.contains(concern) {
            selectedConcerns.remove(concern)
        } else {
            selectedConcerns.insert(concern)
        }
    }

    func buildPrompt(userSummary: String) -> [DeepseekMessage] {
        let systemContent = [
            NSLocalizedString("NaturalSolutions.SystemPersona", comment: ""),
            userSummary,
            NSLocalizedString("NaturalSolutions.SystemFormat", comment: "")
        ].joined(separator: "\n\n")
        
        var userParts: [String] = []
        if !selectedConcerns.isEmpty {
            let joined = selectedConcerns.joined(separator: ", ")
            userParts.append(String(format: NSLocalizedString("NaturalSolutions.UserConcerns", comment: ""), joined))
        }
        if includeOther && !otherConcernsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userParts.append(String(format: NSLocalizedString("NaturalSolutions.UserOtherConcerns", comment: ""), otherConcernsText))
        }
        if !feelingsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userParts.append(String(format: NSLocalizedString("NaturalSolutions.UserFeelings", comment: ""), feelingsText))
        }

        let userContent = userParts.joined(separator: "\n")

        return [
            DeepseekMessage(role: "system", content: systemContent),
            DeepseekMessage(role: "user", content: userContent.isEmpty ? NSLocalizedString("NaturalSolutions.DefaultUserPrompt", comment: "") : userContent)
        ]
    }

    @MainActor
    func requestNaturalSolutions(userSummary: String) async {
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
            context: "NaturalSolutionsViewViewModel.requestNaturalSolutions",
            onSuccess: { [weak self] result in
                self?.resultText = result
            }
        )
    }

    // MARK: - Persist
    @MainActor
    func saveNaturalSolutions(userId: String, firestoreManager: FirestoreManager) {
        guard !resultText.isEmpty else { return }
        
        performAsyncOperation(
            operation: {
                // Extract remedies from the result text
                let remedies = self.extractRemedies(from: self.resultText)
                
                let model = NaturalSolitionsModel(
                    id: nil,
                    userId: userId,
                    question: self.buildConcernsString(),
                    remedies: remedies,
                    createdAt: Date()
                )
                
                try await firestoreManager.addDocument(to: "naturalSolutions", object: model)
                return true
            },
            context: "NaturalSolutionsViewViewModel.saveNaturalSolutions",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("NaturalSolutions.SaveSuccess", comment: ""))
            }
        )
    }
    
    private func extractRemedies(from text: String) -> [String] {
        // Extract remedies by looking for bullet points or numbered items
        let lines = text.components(separatedBy: .newlines)
        var remedies: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            // Look for bullet points, numbers, or dashes
            if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("•") ||
               trimmed.range(of: "^\\d+[\\.\\)]", options: .regularExpression) != nil {
                let cleaned = trimmed
                    .replacingOccurrences(of: "^[•\\-\\d+\\.\\)\\s]+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty {
                    remedies.append(cleaned)
                }
            }
        }
        
        return remedies.isEmpty ? [text] : remedies
    }
    
    private func buildConcernsString() -> String {
        var concerns: [String] = Array(selectedConcerns)
        if includeOther {
            let trimmed = otherConcernsText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { concerns.append(trimmed) }
        }
        return concerns.joined(separator: ", ")
    }
}
