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
        guard let start = response.firstIndex(of: "[") , let end = response.lastIndex(of: "]") else {
            return nil
        }
        let jsonString = String(response[start...end])
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    /// Extracts the first JSON object substring and decodes it into the requested type.
    static func decodeJSONObject<T: Decodable>(from response: String, as type: T.Type = T.self) -> T? {
        guard let start = response.firstIndex(of: "{") , let end = response.lastIndex(of: "}") else {
            return nil
        }
        let jsonString = String(response[start...end])
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}


