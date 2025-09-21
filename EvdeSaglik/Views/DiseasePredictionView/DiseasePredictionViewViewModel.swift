//
//  DiseasePredictionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

struct DiseasePredictionResult: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    let diseaseName: String
    let confidence: Double // 0-100
    let description: String
}

final class DiseasePredictionViewViewModel: BaseViewModel {
    @Published var predefinedSymptoms: [String] = [
        NSLocalizedString("DiseasePrediction.Symptom.Headache", comment: ""),
        NSLocalizedString("DiseasePrediction.Symptom.Fever", comment: ""),
        NSLocalizedString("DiseasePrediction.Symptom.Cough", comment: ""),
        NSLocalizedString("DiseasePrediction.Symptom.Nausea", comment: ""),
        NSLocalizedString("DiseasePrediction.Symptom.Fatigue", comment: ""),
        NSLocalizedString("DiseasePrediction.Symptom.ChestPain", comment: ""),
        NSLocalizedString("DiseasePrediction.Symptom.AbdominalPain", comment: ""),
        NSLocalizedString("DiseasePrediction.Symptom.Dizziness", comment: "")
    ]
    @Published var selectedSymptoms: Set<String> = []
    @Published var includeOther: Bool = false
    @Published var otherSymptomsText: String = ""
    @Published var feelingsText: String = ""
    @Published var durationText: String = ""

    @Published var results: [DiseasePredictionResult] = []
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
            NSLocalizedString("DiseasePrediction.SystemPersona", comment: ""),
            userSummary,
            NSLocalizedString("DiseasePrediction.SystemFormat", comment: "")
        ].joined(separator: "\n\n")

        var userParts: [String] = []
        if !selectedSymptoms.isEmpty {
            let joined = selectedSymptoms.joined(separator: ", ")
            userParts.append(String(format: NSLocalizedString("DiseasePrediction.UserSymptoms", comment: ""), joined))
        }
        if includeOther && !otherSymptomsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userParts.append(String(format: NSLocalizedString("DiseasePrediction.UserOtherSymptoms", comment: ""), otherSymptomsText))
        }
        if !feelingsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userParts.append(String(format: NSLocalizedString("DiseasePrediction.UserFeelings", comment: ""), feelingsText))
        }
        if !durationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userParts.append(String(format: NSLocalizedString("DiseasePrediction.UserDuration", comment: ""), durationText))
        }

        let userContent = userParts.joined(separator: "\n")

        return [
            DeepseekMessage(role: "system", content: systemContent),
            DeepseekMessage(role: "user", content: userContent.isEmpty ? NSLocalizedString("DiseasePrediction.DefaultUserPrompt", comment: "") : userContent)
        ]
    }

    @MainActor
    func requestPredictions(userSummary: String) async {
        performAsyncOperation(
            operation: {
                let messages = self.buildPrompt(userSummary: userSummary)
                let response = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messages)
                let parsed: [DiseasePredictionResult] = self.parseResults(from: response)
                return parsed
            },
            context: "DiseasePredictionViewViewModel.requestPredictions",
            onSuccess: { [weak self] results in
                self?.results = results
            }
        )
    }

    private func parseResults(from response: String) -> [DiseasePredictionResult] {
        // Use generic parser first
        struct Item: Codable { let disease: String; let confidence: Double; let description: String }
        if let items: [Item] = AIResponseParser.decodeJSONArray(from: response, as: [Item].self) {
            return items.map { DiseasePredictionResult(diseaseName: $0.disease, confidence: max(0, min(100, $0.confidence)), description: $0.description) }
        }
        // Heuristic: lines like "Migraine - 72% - Severe headache condition"
        var results: [DiseasePredictionResult] = []
        let lines = response.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let pattern = #"^(.+?)\s*[-: ]\s*(\d{1,3})%\s*[-: ]\s*(.+)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        for line in lines {
            guard let regex = regex else { continue }
            let range = NSRange(location: 0, length: line.utf16.count)
            if let match = regex.firstMatch(in: line, options: [], range: range), match.numberOfRanges == 4 {
                if let diseaseRange = Range(match.range(at: 1), in: line), 
                   let confRange = Range(match.range(at: 2), in: line),
                   let descRange = Range(match.range(at: 3), in: line) {
                    let name = String(line[diseaseRange]).trimmingCharacters(in: .whitespaces)
                    let conf = Double(line[confRange]) ?? 0
                    let desc = String(line[descRange]).trimmingCharacters(in: .whitespaces)
                    results.append(DiseasePredictionResult(diseaseName: name, confidence: max(0, min(100, conf)), description: desc))
                }
            }
        }
        return results
    }

    // MARK: - Persist
    @MainActor
    func savePredictions(userId: String, firestoreManager: FirestoreManager) {
        guard !results.isEmpty else { return }
        
        performAsyncOperation(
            operation: {
                let symptomList: [String] = self.buildSymptomsArray()
                let diseases: [PredictedDisease] = self.results
                    .sorted { $0.confidence > $1.confidence }
                    .map { PredictedDisease(name: $0.diseaseName, probability: $0.confidence) }
                let model = DiseasePredictionModel(
                    id: nil,
                    userId: userId,
                    symptoms: symptomList,
                    possibleDiseases: diseases,
                    createdAt: Date()
                )
                
                try await firestoreManager.addDocument(to: "diseasePredictions", object: model)
                return true
            },
            context: "DiseasePredictionViewViewModel.savePredictions",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("DiseasePrediction.SaveSuccess", comment: ""))
            }
        )
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