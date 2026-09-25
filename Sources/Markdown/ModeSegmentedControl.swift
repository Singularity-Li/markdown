import AppKit

/// 保留 NSSegmentedControl 的选择、键盘和辅助功能行为，绘制稳定的品牌选中底色。
final class ModeSegmentedControl: NSSegmentedControl {
    override func draw(_ dirtyRect: NSRect) {
        let background = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
        NSColor.controlBackgroundColor.withAlphaComponent(0.7).setFill()
        background.fill()
        NSColor.separatorColor.withAlphaComponent(0.4).setStroke()
        background.lineWidth = 1
        background.stroke()
        guard segmentCount > 0 else { return }
        let width = bounds.width / CGFloat(segmentCount)
        for index in 0..<segmentCount {
            let segment = NSRect(x: bounds.minX + CGFloat(index) * width, y: bounds.minY,
                                 width: width, height: bounds.height)
            let selected = isSelected(forSegment: index)
            if selected {
                AppTheme.accentNSColor.withAlphaComponent(isEnabled ? 1 : 0.35).setFill()
                NSBezierPath(roundedRect: segment.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6).fill()
            }
            let text = (label(forSegment: index) ?? "") as NSString
            let color: NSColor = !isEnabled ? .disabledControlTextColor : (selected ? .white : .labelColor)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: color
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: segment.midX - size.width / 2, y: segment.midY - size.height / 2),
                      withAttributes: attributes)
        }
    }

    override var focusRingMaskBounds: NSRect { bounds }
    override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
    }
}
