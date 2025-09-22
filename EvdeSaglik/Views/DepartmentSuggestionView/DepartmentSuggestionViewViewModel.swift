//
//  DepartmentSuggestionViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI

struct DepartmentSuggestionResult: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let name: String
    let confidence: Double // 0-100
}

final class DepartmentSuggestionViewViewModel: BaseViewModel {
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

    @Published var results: [DepartmentSuggestionResult] = []
    @Published var isSaving: Bool = false

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
        performAsyncOperation(
            operation: {
                let messages = self.buildPrompt(userSummary: userSummary)
                let response = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messages)
                let parsed: [DepartmentSuggestionResult] = self.parseResults(from: response)
                return parsed
            },
            context: "DepartmentSuggestionViewViewModel.requestSuggestions",
            onSuccess: { [weak self] results in
                self?.results = results
            }
        )
    }

    private func parseResults(from response: String) -> [DepartmentSuggestionResult] {
        print("🔍 Parsing DepartmentSuggestion response:")
        print("Response: \(response)")
        
        // Use generic parser first
        struct Item: Codable { let department: String; let confidence: Double }
        if let items: [Item] = AIResponseParser.decodeJSONArray(from: response, as: [Item].self) {
            print("✅ JSON parsing successful: \(items)")
            return items.map { DepartmentSuggestionResult(name: $0.department, confidence: max(0, min(100, $0.confidence))) }
        }
        
        // Try alternative JSON structure
        struct AltItem: Codable { let name: String; let confidence: Double }
        if let items: [AltItem] = AIResponseParser.decodeJSONArray(from: response, as: [AltItem].self) {
            print("✅ Alternative JSON parsing successful: \(items)")
            return items.map { DepartmentSuggestionResult(name: $0.name, confidence: max(0, min(100, $0.confidence))) }
        }
        // Try Turkish field names with diacritics and flexible numeric parsing
        struct TrItem: Decodable {
            let name: String?
            let confidence: Double?
            
            enum CodingKeys: String, CodingKey {
                case bolum = "bölüm"
                case alan
                case ad
                case guvenYuzdesi = "güven yüzdesi"
                case guven
                case yuzde
            }
            
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                // name
                self.name = (try? c.decode(String.self, forKey: .bolum)) ??
                           (try? c.decode(String.self, forKey: .alan)) ??
                           (try? c.decode(String.self, forKey: .ad))
                // confidence can be number or string like "65%"
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
            }
        }
        if let items: [TrItem] = AIResponseParser.decodeJSONArray(from: response, as: [TrItem].self) {
            print("✅ Turkish JSON parsing successful: \(items)")
            return items.compactMap {
                guard let n = $0.name, let c = $0.confidence else { return nil }
                return DepartmentSuggestionResult(name: n, confidence: max(0, min(100, c)))
            }
        }
        
        // Heuristic: lines like "Cardiology - 72%" or "Cardiology: 72%"
        var results: [DepartmentSuggestionResult] = []
        let lines = response.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Multiple patterns to try (EN/TR, normal and reversed)
        let patterns = [
            #"^(.+?)\s*[-:]\s*(\d{1,3})%$"#,                 // "Cardiology - 72%"
            #"^(.+?)\s*[-:]\s*(\d{1,3})$"#,                  // "Cardiology - 72"
            #"^(.+?)\s*\((\d{1,3})%\)$"#,                    // "Cardiology (72%)"
            #"^(.+?)\s*\((\d{1,3})\)$"#,                     // "Cardiology (72)"
            #"(?i)^g[üu]ven\s*y[üu]zdesi\s*[:\-]?\s*(\d{1,3})%?.*?[:\-]\s*(.+)$"#, // "Güven yüzdesi: 72% - Kardiyoloji"
            #"(?i)^confidence\s*[:\-]?\s*(\d{1,3})%?.*?[:\-]\s*(.+)$"#             // "Confidence: 72% - Cardiology"
        ]
        
        for line in lines {
            if line.isEmpty { continue }
            
            for (idx, pattern) in patterns.enumerated() {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(location: 0, length: line.utf16.count)
                    if let match = regex.firstMatch(in: line, options: [], range: range) {
                        var name: String?
                        var confString: String?
                        if idx <= 3 { // normal patterns (name, conf)
                            if match.numberOfRanges >= 3,
                               let depRange = Range(match.range(at: 1), in: line),
                               let confRange = Range(match.range(at: 2), in: line) {
                                name = String(line[depRange]).trimmingCharacters(in: .whitespaces)
                                confString = String(line[confRange])
                            }
                        } else { // reversed patterns (conf, name)
                            if match.numberOfRanges >= 3,
                               let confRange = Range(match.range(at: 1), in: line),
                               let depRange = Range(match.range(at: 2), in: line) {
                                name = String(line[depRange]).trimmingCharacters(in: .whitespaces)
                                confString = String(line[confRange])
                            }
                        }
                        if var n = name, let confStr = confString, let conf = Double(confStr) {
                            // If name accidentally captured a label like "Güven yüzdesi", try to extract trailing name after '-' or ':'
                            let lower = n.lowercased()
                            if lower.contains("güven yüzdesi") || lower.contains("guven yuzdesi") || lower.contains("confidence") {
                                if let split = line.split(separator: "-").last ?? line.split(separator: ":").last {
                                    n = String(split).trimmingCharacters(in: .whitespaces)
                                }
                            }
                            if !n.isEmpty && !n.lowercased().contains("güven") {
                                results.append(DepartmentSuggestionResult(name: n, confidence: max(0, min(100, conf))))
                                break
                            }
                        }
                    }
                }
            }
        }
        
        // Fallback: bullet list without explicit confidence
        if results.isEmpty {
            for line in lines where line.hasPrefix("-") || line.hasPrefix("•") {
                let n = line.dropFirst().trimmingCharacters(in: .whitespaces)
                if !n.isEmpty { results.append(DepartmentSuggestionResult(name: n, confidence: 0)) }
            }
        }
        
        print("✅ Heuristic parsing result: \(results)")
        return results
    }

    // MARK: - Persist
    @MainActor
    func saveSuggestions(userId: String, firestoreManager: FirestoreManager) {
        guard !results.isEmpty else { return }
        
        performAsyncOperation(
            operation: {
                let symptomList: [String] = self.buildSymptomsArray()
                let departments: [String] = self.results
                    .sorted { $0.confidence > $1.confidence }
                    .map { "\($0.name) (\(Int($0.confidence))%)" }
                let model = DepartmentSuggestionModel(
                    id: nil,
                    userId: userId,
                    symptoms: symptomList,
                    suggestedDepartments: departments,
                    createdAt: Date()
                )
                
                try await firestoreManager.addDocument(to: "departmentSuggestions", object: model)
                return true
            },
            context: "DepartmentSuggestionViewViewModel.saveSuggestions",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("DepartmentSuggestion.SaveSuccess", comment: ""))
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
