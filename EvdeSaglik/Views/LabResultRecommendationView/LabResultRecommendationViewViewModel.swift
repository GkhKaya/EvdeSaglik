//
//  LabResultRecommendationViewViewModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation
import SwiftUI
import PDFKit
import Vision

struct LabAnalysisSection: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let lines: [String]
}

struct LabAbnormalItem: Identifiable, Equatable {
    let id = UUID()
    let test: String
    let value: Double
    let unit: String
    let referenceRange: String
    let remedy: String
    let doctorAdvice: String
}

final class LabResultRecommendationViewViewModel: BaseViewModel {
    @Published var extractedTables: [[String]] = []
    @Published var analysisResult: String = ""
    @Published var sections: [LabAnalysisSection] = []
    @Published var abnormalItems: [LabAbnormalItem] = []
    @Published var isSaving: Bool = false
    @Published var saveMessage: String? = nil
    
    func extractTablesFromPDF(_ pdfDocument: PDFDocument) async -> [[String]] {
        var allRows: [[String]] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // Convert PDF page to image
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { context in
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            // Vision-based table row/column extraction
            let rows = await extractRowsAndCellsFromImage(image, pageSize: pageRect.size)
            
            // Debug logs
            print("\n=== PDF Page #\(pageIndex + 1) / \(pdfDocument.pageCount) ===")
            if rows.isEmpty {
                print("No table-like rows detected on this page.")
            } else {
                for (rIndex, row) in rows.enumerated() {
                    print("  [row \(rIndex)] cells=\(row.count) -> \(row)")
                }
            }
            
            allRows.append(contentsOf: rows)
        }
        
        print("\n=== Extraction finished. Total rows: \(allRows.count) ===")
        return allRows
    }
    
    private func extractRowsAndCellsFromImage(_ image: UIImage, pageSize: CGSize) async -> [[String]] {
        struct Token { let text: String; let xStart: CGFloat; let xEnd: CGFloat; let yCenter: CGFloat }
        var tokens: [Token] = []
        
        // Run text recognition
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            guard let cgImage = image.cgImage else {
                continuation.resume()
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                defer { continuation.resume() }
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                for obs in observations {
                    guard let top = obs.topCandidates(1).first else { continue }
                    // VN's boundingBox is normalized (0..1) with origin at bottom-left
                    let box = obs.boundingBox
                    let xStart = box.minX
                    let xEnd = box.maxX
                    let yCenter = (box.minY + box.maxY) / 2.0
                    tokens.append(Token(text: top.string, xStart: xStart, xEnd: xEnd, yCenter: yCenter))
                }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            // Hint languages common for lab reports
            request.recognitionLanguages = ["tr-TR", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
        
        if tokens.isEmpty { return [] }
        
        // Group tokens into rows using yCenter proximity
        let rowThreshold: CGFloat = 0.015 // normalized space threshold between lines
        var rows: [[Token]] = []
        let sortedByY = tokens.sorted { $0.yCenter > $1.yCenter } // top to bottom visually
        
        for token in sortedByY {
            if var lastRow = rows.last, let last = lastRow.first {
                if abs(token.yCenter - last.yCenter) <= rowThreshold {
                    lastRow.append(token)
                    rows[rows.count - 1] = lastRow
                } else {
                    rows.append([token])
                }
            } else {
                rows.append([token])
            }
        }
        
        // For each row, sort by xStart and split into cells by large gaps
        let gapThreshold: CGFloat = 0.02
        var tableRows: [[String]] = []
        
        for var row in rows {
            row.sort { $0.xStart < $1.xStart }
            var cells: [String] = []
            var current = ""
            var prevXEnd: CGFloat? = nil
            
            for t in row {
                if let prev = prevXEnd, (t.xStart - prev) > gapThreshold {
                    // New cell when a big horizontal gap is detected
                    if !current.trimmingCharacters(in: .whitespaces).isEmpty { cells.append(current.trimmingCharacters(in: .whitespaces)) }
                    current = t.text
                } else {
                    current = current.isEmpty ? t.text : (current + " " + t.text)
                }
                prevXEnd = max(prevXEnd ?? t.xEnd, t.xEnd)
            }
            if !current.trimmingCharacters(in: .whitespaces).isEmpty {
                cells.append(current.trimmingCharacters(in: .whitespaces))
            }
            
            // Heuristic: only keep rows that look like table rows (>= 2 cells)
            if cells.count >= 2 { tableRows.append(cells) }
        }
        
        return tableRows
    }
    
    func buildPrompt(userSummary: String, tables: [[String]]) -> [DeepseekMessage] {
        let systemContent = [
            NSLocalizedString("LabResult.SystemPersona", comment: ""),
            userSummary,
            NSLocalizedString("LabResult.SystemFormat", comment: "")
        ].joined(separator: "\n\n")
        
        // Rebuild a simple tabular text preserving row/column separation with tabs
        let tableData = tables.map { row in
            row.joined(separator: "\t")
        }.joined(separator: "\n")
        
        let userContent = String(format: NSLocalizedString("LabResult.UserPrompt", comment: ""), tableData)
        
        return [
            DeepseekMessage(role: "system", content: systemContent),
            DeepseekMessage(role: "user", content: userContent)
        ]
    }
    
    @MainActor
    func analyzeLabResults(userSummary: String, tables: [[String]]) async {
        print("🔍 Analyzing lab results with \(tables.count) table rows")
        print("Tables: \(tables)")
        
        performAsyncOperation(
            operation: {
                let messages = self.buildPrompt(userSummary: userSummary, tables: tables)
                print("📤 Sending prompt to AI: \(messages)")
                let response = try await OpenRouterDeepseekManager.shared.performChatRequest(messages: messages)
                print("📥 Received AI response: \(response)")
                // Try to decode JSON array of abnormal items
                struct AbnormalItemDTO: Decodable { let test: String; let value: Double; let unit: String; let referenceRange: String; let isAbnormal: Bool; let remedy: String; let doctorAdvice: String }
                if let items: [AbnormalItemDTO] = AIResponseParser.decodeJSONArray(from: response, as: [AbnormalItemDTO].self) {
                    let mapped = items.filter { $0.isAbnormal }.map {
                        LabAbnormalItem(test: $0.test, value: $0.value, unit: $0.unit, referenceRange: $0.referenceRange, remedy: $0.remedy, doctorAdvice: $0.doctorAdvice)
                    }
                    self.abnormalItems = mapped
                    // Also produce a plain text for share/copy if needed
                    let lines: [String] = mapped.map { item in
                        "\(item.test): \(item.value) \(item.unit) (\(item.referenceRange))"
                    }
                    let text = lines.joined(separator: "\n")
                    let section = LabAnalysisSection(title: NSLocalizedString("LabResult.Title", comment: ""), lines: lines)
                    return (text, [section])
                }
                // Fallback to previous parsing if JSON not returned
                var cleaned = response
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                cleaned = cleaned.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
                cleaned = cleaned.replacingOccurrences(of: #"#"#, with: "", options: .regularExpression)
                let sections = Self.parseAnalysisIntoSections(cleaned)
                return (cleaned, sections)
            },
            context: "LabResultRecommendationViewViewModel.analyzeLabResults",
            onSuccess: { [weak self] result in
                self?.analysisResult = result.0
                self?.sections = result.1
            }
        )
    }
    
    static func parseAnalysisIntoSections(_ text: String) -> [LabAnalysisSection] {
        let lines = text.components(separatedBy: .newlines)
        var sections: [LabAnalysisSection] = []
        var currentTitle: String?
        var currentLines: [String] = []
        
        let headerPattern = try? NSRegularExpression(pattern: "^\\s*(\\d+)[\\)\\.]\\s*(.+)$")
        
        func flushSection() {
            if let title = currentTitle {
                let trimmedItems = currentLines.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                sections.append(LabAnalysisSection(title: title, lines: trimmedItems))
            } else if !currentLines.isEmpty {
                // Fallback unnamed section
                let trimmedItems = currentLines.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                sections.append(LabAnalysisSection(title: "", lines: trimmedItems))
            }
            currentTitle = nil
            currentLines = []
        }
        
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            if let headerPattern = headerPattern {
                let range = NSRange(location: 0, length: line.utf16.count)
                if let match = headerPattern.firstMatch(in: line, options: [], range: range), match.numberOfRanges >= 3,
                   let titleRange = Range(match.range(at: 2), in: line) {
                    // Start new section
                    flushSection()
                    currentTitle = String(line[titleRange]).trimmingCharacters(in: .whitespaces)
                    continue
                }
            }
            
            // Bullet-like lines or plain text become items
            currentLines.append(line)
        }
        
        flushSection()
        return sections
    }
    
    // MARK: - Persist
    @MainActor
    func saveLabResults(userId: String, firestoreManager: FirestoreManager) {
        // Only save if we have parsed abnormal items
        guard !abnormalItems.isEmpty else { return }
        
        performAsyncOperation(
            operation: {
                // Save only abnormal values (already filtered into abnormalItems)
                var labResults: [String: Double] = [:]
                for item in self.abnormalItems {
                    labResults[item.test] = item.value
                }
                
                // Natural solutions from parsed items' remedies
                let naturalSolutions: [String] = self.abnormalItems
                    .map { $0.remedy.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                // Try to extract medications from the full analysis text as a fallback
                let medications: [String] = self.extractSuggestedMedications(from: self.analysisResult)
                
                let model = LabResultRecommendationModel(
                    id: nil,
                    userId: userId,
                    labResults: labResults,
                    suggestedMedications: medications,
                    suggestedNaturalSolutions: naturalSolutions,
                    createdAt: Date()
                )
                
                try await firestoreManager.addDocument(to: "labResultRecommendations", object: model)
                return true
            },
            context: "LabResultRecommendationViewViewModel.saveLabResults",
            onSuccess: { [weak self] _ in
                self?.showSuccess(NSLocalizedString("LabResult.SaveSuccess", comment: ""))
            }
        )
    }
    
    private func extractSuggestedMedications(from text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var medications: [String] = []
        for line in lines {
            if line.lowercased().contains("ilaç") || line.lowercased().contains("medication") {
                medications.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return medications
    }
    
    private func extractSuggestedNaturalSolutions(from text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var solutions: [String] = []
        for line in lines {
            if line.lowercased().contains("doğal") || line.lowercased().contains("natural") {
                solutions.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return solutions
    }
}