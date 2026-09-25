import SwiftUI
import AppKit

/// 品牌强调色与 App 图标 D 保持一致：sRGB #A63D50。
enum AppTheme {
    static let accentNSColor = NSColor(srgbRed: 166.0 / 255, green: 61.0 / 255, blue: 80.0 / 255, alpha: 1)
    static let accent = Color(nsColor: accentNSColor)
}
