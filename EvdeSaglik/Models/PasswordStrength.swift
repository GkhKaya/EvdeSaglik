//
//  PasswordStrength.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import Foundation
import SwiftUI // Added for Color

enum PasswordStrength: Int, CaseIterable {
    case none = 0
    case weak = 1
    case medium = 2
    case strong = 3
    case veryStrong = 4
    
    var localizedString: String {
        switch self {
        case .none: return ""
        case .weak: return NSLocalizedString("Password.Strength.Weak", comment: "Weak")
        case .medium: return NSLocalizedString("Password.Strength.Medium", comment: "Medium")
        case .strong: return NSLocalizedString("Password.Strength.Strong", comment: "Strong")
        case .veryStrong: return NSLocalizedString("Password.Strength.VeryStrong", comment: "Very Strong")
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .yellow
        case .veryStrong: return .green
        }
    }
}
