//
//  NaturalSolutionsViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

final class NaturalSolutionsViewViewModel: ObservableObject {
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

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
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
    func saveNaturalSolutions(userId: String, firestoreManager: FirestoreManager) {
        guard !resultText.isEmpty else { return }
        
        isSaving = true
        saveMessage = nil
        
        // Extract remedies from the result text
        let remedies = extractRemedies(from: resultText)
        
        let model = NaturalSolitionsModel(
            id: nil,
            userId: userId,
            question: buildConcernsString(),
            remedies: remedies,
            createdAt: Date()
        )
        
        firestoreManager.addDocument(to: "naturalSolutions", object: model) { [weak self] err in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let err = err {
                    self?.saveMessage = NSLocalizedString("NaturalSolutions.SaveError", comment: "")
                    print("Firestore save error: \(err)")
                } else {
                    self?.saveMessage = NSLocalizedString("NaturalSolutions.SaveSuccess", comment: "")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.saveMessage = nil
                    }
                }
            }
        }
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
