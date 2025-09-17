//
//  DepartmentSuggestionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

struct DepartmentSuggestionResult: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    let name: String
    let confidence: Double // 0-100
}

final class DepartmentSuggestionViewViewModel: ObservableObject {
    @Published var predefinedSymptoms: [String] = [
        NSLocalizedString("DepartmentSuggestion.Symptom.Headache", comment: ""),
        NSLocalizedString("DepartmentSuggestion.Symptom.Nausea", comment: ""),
        NSLocalizedString("DepartmentSuggestion.Symptom.ChestPain", comment: ""),
        NSLocalizedString("DepartmentSuggestion.Symptom.Cough", comment: ""),
        NSLocalizedString("DepartmentSuggestion.Symptom.SkinRash", comment: ""),
        NSLocalizedString("DepartmentSuggestion.Symptom.JointPain", comment: ""),
        NSLocalizedString("DepartmentSuggestion.Symptom.Fatigue", comment: ""),
        NSLocalizedString("DepartmentSuggestion.Symptom.Fever", comment: "")
    ]
    @Published var selectedSymptoms: Set<String> = []
    @Published var includeOther: Bool = false
    @Published var otherSymptomsText: String = ""
    @Published var feelingsText: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var results: [DepartmentSuggestionResult] = []
    @Published var isSaving: Bool = false
    @Published var saveMessage: String? = nil

    func toggleSymptom(_ symptom: String) {
        if selectedSymptoms.contains(symptom) {
            selectedSymptoms.remove(symptom)
        } else {
            selectedSymptoms.insert(symptom)
        }
    }

    func buildPrompt(userSummary: String) -> [DeepseekMessage] {
        let systemContent = [
            NSLocalizedString("DepartmentSuggestion.SystemPersona", comment: ""),
            userSummary,
            NSLocalizedString("DepartmentSuggestion.SystemFormat", comment: "")
        ].joined(separator: "\n\n")

        var userParts: [String] = []
        if !selectedSymptoms.isEmpty {
            let joined = selectedSymptoms.joined(separator: ", ")
            userParts.append(String(format: NSLocalizedString("DepartmentSuggestion.UserSymptoms", comment: ""), joined))
        }
        if includeOther && !otherSymptomsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userParts.append(String(format: NSLocalizedString("DepartmentSuggestion.UserOtherSymptoms", comment: ""), otherSymptomsText))
        }
        if !feelingsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userParts.append(String(format: NSLocalizedString("DepartmentSuggestion.UserFeelings", comment: ""), feelingsText))
        }

        let userContent = userParts.joined(separator: "\n")

        return [
            DeepseekMessage(role: "system", content: systemContent),
            DeepseekMessage(role: "user", content: userContent.isEmpty ? NSLocalizedString("DepartmentSuggestion.DefaultUserPrompt", comment: "") : userContent)
        ]
    }

    @MainActor
    func requestSuggestions(userSummary: String) async {
        errorMessage = nil
        results = []
        isLoading = true
        defer { isLoading = false }

        let messages = buildPrompt(userSummary: userSummary)
        do {
            let response = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messages)
            // Try to extract JSON from the response
            let parsed: [DepartmentSuggestionResult] = parseResults(from: response)
            self.results = parsed
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func parseResults(from response: String) -> [DepartmentSuggestionResult] {
        // Use generic parser first
        struct Item: Codable { let department: String; let confidence: Double }
        if let items: [Item] = AIResponseParser.decodeJSONArray(from: response, as: [Item].self) {
            return items.map { DepartmentSuggestionResult(name: $0.department, confidence: max(0, min(100, $0.confidence))) }
        }
        // Heuristic: lines like "Cardiology - 72%"
        var results: [DepartmentSuggestionResult] = []
        let lines = response.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let pattern = #"^(.+?)\s*[-: ]\s*(\d{1,3})%$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        for line in lines {
            guard let regex = regex else { continue }
            let range = NSRange(location: 0, length: line.utf16.count)
            if let match = regex.firstMatch(in: line, options: [], range: range), match.numberOfRanges == 3 {
                if let depRange = Range(match.range(at: 1), in: line), let confRange = Range(match.range(at: 2), in: line) {
                    let name = String(line[depRange]).trimmingCharacters(in: .whitespaces)
                    let conf = Double(line[confRange]) ?? 0
                    results.append(DepartmentSuggestionResult(name: name, confidence: max(0, min(100, conf))))
                }
            }
        }
        return results
    }

    // MARK: - Persist
    @MainActor
    func saveSuggestions(userId: String, firestoreManager: FirestoreManager) {
        guard !results.isEmpty else { return }
        
        isSaving = true
        saveMessage = nil
        
        let symptomList: [String] = buildSymptomsArray()
        let departments: [String] = results
            .sorted { $0.confidence > $1.confidence }
            .map { "\($0.name) (\(Int($0.confidence))%)" }
        let model = DepartmentSuggestionModel(
            id: nil,
            userId: userId,
            symptoms: symptomList,
            suggestedDepartments: departments,
            createdAt: Date()
        )
        
        firestoreManager.addDocument(to: "departmentSuggestions", object: model) { [weak self] err in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let err = err {
                    self?.saveMessage = NSLocalizedString("DepartmentSuggestion.SaveError", comment: "")
                    print("Firestore save error: \(err)")
                } else {
                    self?.saveMessage = NSLocalizedString("DepartmentSuggestion.SaveSuccess", comment: "")
                    // Clear message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.saveMessage = nil
                    }
                }
            }
        }
    }
    
    private func buildSymptomsArray() -> [String] {
        var list: [String] = Array(selectedSymptoms)
        if includeOther {
            let trimmed = otherSymptomsText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { list.append(trimmed) }
        }
        return list
    }
}
