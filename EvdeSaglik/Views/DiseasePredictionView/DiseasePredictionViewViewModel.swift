//
//  DiseasePredictionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

struct DiseasePredictionResult: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
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
        print("🔍 Parsing DiseasePrediction response:")
        print("Response: \(response)")
        
        // Use generic parser first
        struct Item: Codable { let disease: String; let confidence: Double; let description: String }
        if let items: [Item] = AIResponseParser.decodeJSONArray(from: response, as: [Item].self) {
            print("✅ JSON parsing successful: \(items)")
            return items.map { DiseasePredictionResult(diseaseName: $0.disease, confidence: max(0, min(100, $0.confidence)), description: $0.description) }
        }
        
        // Try alternative JSON structure
        struct AltItem: Codable { let name: String; let confidence: Double; let description: String }
        if let items: [AltItem] = AIResponseParser.decodeJSONArray(from: response, as: [AltItem].self) {
            print("✅ Alternative JSON parsing successful: \(items)")
            return items.map { DiseasePredictionResult(diseaseName: $0.name, confidence: max(0, min(100, $0.confidence)), description: $0.description) }
        }
        // Try Turkish field names with diacritics and percent strings
        struct TrItem: Decodable {
            let name: String?
            let confidence: Double?
            let description: String?
            enum CodingKeys: String, CodingKey {
                case hastalik
                case ad
                case isim
                case guvenYuzdesi
                case guven
                case yuzde
                case aciklama
            }
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                self.name = (try? c.decode(String.self, forKey: .hastalik)) ??
                            (try? c.decode(String.self, forKey: .ad)) ??
                            (try? c.decode(String.self, forKey: .isim))
                if let d = try? c.decode(Double.self, forKey: .guvenYuzdesi) {
                    self.confidence = d
                } else if let d = try? c.decode(Double.self, forKey: .guven) {
                    self.confidence = d
                } else if let d = try? c.decode(Double.self, forKey: .yuzde) {
                    self.confidence = d
                } else if let s = try? c.decode(String.self, forKey: .guvenYuzdesi) {
                    self.confidence = Double(s.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces))
                } else if let s = try? c.decode(String.self, forKey: .guven) {
                    self.confidence = Double(s.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces))
                } else if let s = try? c.decode(String.self, forKey: .yuzde) {
                    self.confidence = Double(s.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces))
                } else {
                    self.confidence = nil
                }
                self.description = (try? c.decode(String.self, forKey: .aciklama))
            }
        }
        if let items: [TrItem] = AIResponseParser.decodeJSONArray(from: response, as: [TrItem].self) {
            print("✅ Turkish JSON parsing successful: \(items)")
            return items.compactMap {
                guard let n = $0.name, let c = $0.confidence else { return nil }
                return DiseasePredictionResult(diseaseName: n, confidence: max(0, min(100, c)), description: $0.description ?? "")
            }
        }
        
        // Heuristic: lines like "Migraine - 72% - Severe headache condition"
        var results: [DiseasePredictionResult] = []
        let lines = response.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Multiple patterns to try (EN/TR, normal and reversed)
        let patterns = [
            #"^(.+?)\s*[-:]\s*(\d{1,3})%\s*[-:]\s*(.+)$"#,  // "Migraine - 72% - Description"
            #"^(.+?)\s*[-:]\s*(\d{1,3})%\s*(.+)$"#,         // "Migraine - 72% Description"
            #"^(.+?)\s*\((\d{1,3})%\)\s*[-:]\s*(.+)$"#,     // "Migraine (72%) - Description"
            #"^(.+?)\s*\((\d{1,3})%\)\s*(.+)$"#,            // "Migraine (72%) Description"
            #"(?i)^g[üu]ven\s*y[üu]zdesi\s*[:\-]?\s*(\d{1,3})%?.*?[:\-]\s*(.+)$"#, // "Güven yüzdesi: 72% - Migren"
            #"(?i)^confidence\s*[:\-]?\s*(\d{1,3})%?.*?[:\-]\s*(.+)$"#             // "Confidence: 72% - Migraine"
        ]
        
        for line in lines {
            if line.isEmpty { continue }
            
            for (idx, pattern) in patterns.enumerated() {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(location: 0, length: line.utf16.count)
                    if let match = regex.firstMatch(in: line, options: [], range: range) {
                        var name: String?
                        var confString: String?
                        var desc: String?
                        if idx <= 3 { // normal patterns (name, conf, desc)
                            if match.numberOfRanges >= 4,
                               let diseaseRange = Range(match.range(at: 1), in: line),
                               let confRange = Range(match.range(at: 2), in: line),
                               let descRange = Range(match.range(at: 3), in: line) {
                                name = String(line[diseaseRange]).trimmingCharacters(in: .whitespaces)
                                confString = String(line[confRange])
                                desc = String(line[descRange]).trimmingCharacters(in: .whitespaces)
                            }
                        } else { // reversed patterns (conf, name) without explicit desc
                            if match.numberOfRanges >= 3,
                               let confRange = Range(match.range(at: 1), in: line),
                               let diseaseRange = Range(match.range(at: 2), in: line) {
                                name = String(line[diseaseRange]).trimmingCharacters(in: .whitespaces)
                                confString = String(line[confRange])
                                // Try to capture description after a second '-' or ':' if present
                                if let range = line.range(of: " - ") ?? line.range(of: ": ") {
                                    let after = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                                    desc = after.isEmpty ? nil : after
                                }
                            }
                        }
                        if var n = name, let confStr = confString, let conf = Double(confStr) {
                            let lower = n.lowercased()
                            if lower.contains("güven yüzdesi") || lower.contains("guven yuzdesi") || lower.contains("confidence") {
                                if let split = line.split(separator: "-").last ?? line.split(separator: ":").last {
                                    n = String(split).trimmingCharacters(in: .whitespaces)
                                }
                            }
                            let descriptionText = desc ?? ""
                            if !n.isEmpty && !n.lowercased().contains("güven") {
                                results.append(DiseasePredictionResult(diseaseName: n, confidence: max(0, min(100, conf)), description: descriptionText))
                                break
                            }
                        }
                    }
                }
            }
        }
        
        print("✅ Heuristic parsing result: \(results)")
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