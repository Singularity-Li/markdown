import SwiftUI
import AppKit

/// 品牌主强调色取自图标 D，次强调色取自图标 M。
enum AppTheme {
    static let toolbarControlHeight: CGFloat = 24
    static let toolbarCornerRadius: CGFloat = 7
    static let transitionDuration: TimeInterval = 0.25
    static let transitionAnimation = Animation.easeInOut(duration: transitionDuration)

    static let accentNSColor = NSColor(srgbRed: 166.0 / 255, green: 61.0 / 255, blue: 80.0 / 255, alpha: 1)
    static let accent = Color(nsColor: accentNSColor)

    // M：sRGB #203B5B，用于需要区分的次级强调。
    static let secondaryAccentNSColor = NSColor(srgbRed: 32.0 / 255, green: 59.0 / 255, blue: 91.0 / 255, alpha: 1)
    static let secondaryAccent = Color(nsColor: secondaryAccentNSColor)
}
