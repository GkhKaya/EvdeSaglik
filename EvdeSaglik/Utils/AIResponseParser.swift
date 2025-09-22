//
//  AIResponseParser.swift
//  EvdeSaglik
//
//  Created by Assistant on 17.09.2025.
//

import Foundation

/// Generic helper to extract and decode JSON (array or object) embedded in LLM text responses.
struct AIResponseParser {
    /// Extracts the first JSON array substring and decodes it into the requested type.
    static func decodeJSONArray<T: Decodable>(from response: String, as type: T.Type = T.self) -> T? {
        // First try to find complete JSON array
        if let start = response.firstIndex(of: "["), let end = response.lastIndex(of: "]") {
            let jsonString = String(response[start...end])
            if let data = jsonString.data(using: .utf8),
               let result = try? JSONDecoder().decode(T.self, from: data) {
                return result
            }
        }
        
        // Try to find JSON array within code blocks
        let codeBlockPattern = #"```(?:json)?\s*(\[.*?\])\s*```"#
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: [.dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: response, options: [], range: NSRange(response.startIndex..., in: response)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: response) {
            let jsonString = String(response[range])
            if let data = jsonString.data(using: .utf8),
               let result = try? JSONDecoder().decode(T.self, from: data) {
                return result
            }
        }
        
        // Try to find JSON array in lines
        let lines = response.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                if let data = trimmed.data(using: .utf8),
                   let result = try? JSONDecoder().decode(T.self, from: data) {
                    return result
                }
            }
        }
        
        return nil
    }
    
    /// Extracts the first JSON object substring and decodes it into the requested type.
    static func decodeJSONObject<T: Decodable>(from response: String, as type: T.Type = T.self) -> T? {
        // First try to find complete JSON object
        if let start = response.firstIndex(of: "{"), let end = response.lastIndex(of: "}") {
            let jsonString = String(response[start...end])
            if let data = jsonString.data(using: .utf8),
               let result = try? JSONDecoder().decode(T.self, from: data) {
                return result
            }
        }
        
        // Try to find JSON object within code blocks
        let codeBlockPattern = #"```(?:json)?\s*(\{.*?\})\s*```"#
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: [.dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: response, options: [], range: NSRange(response.startIndex..., in: response)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: response) {
            let jsonString = String(response[range])
            if let data = jsonString.data(using: .utf8),
               let result = try? JSONDecoder().decode(T.self, from: data) {
                return result
            }
        }
        
        return nil
    }
}


