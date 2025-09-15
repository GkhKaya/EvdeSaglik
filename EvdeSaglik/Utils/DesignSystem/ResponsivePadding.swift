//
//  ResponsivePadding.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import SwiftUI

struct ResponsivePadding {
    private static var paddingScaleFactor: CGFloat {
        return UIScreen.isPad ? 1.5 : 1.0 // Adjust scale factor for iPad
    }

    static let xSmall: CGFloat = UIScreen.screenWidth * 0.01 * paddingScaleFactor
    static let small: CGFloat = UIScreen.screenWidth * 0.02 * paddingScaleFactor
    static let medium: CGFloat = UIScreen.screenWidth * 0.04 * paddingScaleFactor
    static let large: CGFloat = UIScreen.screenWidth * 0.06 * paddingScaleFactor
    static let extraLarge: CGFloat = UIScreen.screenWidth * 0.08 * paddingScaleFactor
}
