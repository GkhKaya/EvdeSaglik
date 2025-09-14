import SwiftUI

struct ResponsiveRadius {
    private static var radiusScaleFactor: CGFloat {
        return UIScreen.isPad ? 1.5 : 1.0 // Adjust scale factor for iPad
    }

    static let small: CGFloat = UIScreen.screenWidth * 0.01 * radiusScaleFactor
    static let medium: CGFloat = UIScreen.screenWidth * 0.02 * radiusScaleFactor
    static let large: CGFloat = UIScreen.screenWidth * 0.03 * radiusScaleFactor
    static let extraLarge: CGFloat = UIScreen.screenWidth * 0.04 * radiusScaleFactor
}
