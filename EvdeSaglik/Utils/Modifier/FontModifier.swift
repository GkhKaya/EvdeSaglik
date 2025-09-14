import SwiftUI

extension Font {
    private static var fontScaleFactor: CGFloat {
        return UIScreen.isPad ? 1.2 : 1.0 // Adjust scale factor for iPad fonts
    }

    static var largeTitleResponsive: Font {
        .custom("SFProDisplay-Regular", size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize * fontScaleFactor)
    }

    static var title1Responsive: Font {
        .custom("SFProDisplay-Regular", size: UIFont.preferredFont(forTextStyle: .title1).pointSize * fontScaleFactor)
    }

    static var title2Responsive: Font {
        .custom("SFProDisplay-Regular", size: UIFont.preferredFont(forTextStyle: .title2).pointSize * fontScaleFactor)
    }

    static var title3Responsive: Font {
        .custom("SFProDisplay-Regular", size: UIFont.preferredFont(forTextStyle: .title3).pointSize * fontScaleFactor)
    }

    static var headlineResponsive: Font {
        .custom("SFProText-Semibold", size: UIFont.preferredFont(forTextStyle: .headline).pointSize * fontScaleFactor)
    }

    static var bodyResponsive: Font {
        .custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: .body).pointSize * fontScaleFactor)
    }

    static var calloutResponsive: Font {
        .custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: .callout).pointSize * fontScaleFactor)
    }

    static var subheadlineResponsive: Font {
        .custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * fontScaleFactor)
    }

    static var footnoteResponsive: Font {
        .custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: .footnote).pointSize * fontScaleFactor)
    }

    static var caption1Responsive: Font {
        .custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: .caption1).pointSize * fontScaleFactor)
    }

    static var caption2Responsive: Font {
        .custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: .caption2).pointSize * fontScaleFactor)
    }
}
