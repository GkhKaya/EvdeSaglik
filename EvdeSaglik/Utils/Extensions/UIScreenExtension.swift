//
//  UIScreenExtension.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//

import SwiftUI
 
extension UIScreen {
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
}
