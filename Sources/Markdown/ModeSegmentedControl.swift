import AppKit
import QuartzCore

/// 保留 NSSegmentedControl 的选择、键盘和辅助功能行为，绘制稳定的品牌选中底色。
final class ModeSegmentedControl: NSSegmentedControl {
    @objc dynamic var highlightPosition: CGFloat = 0 {
        didSet { needsDisplay = true }
    }
    private var targetSegment: Int?

    override class func defaultAnimation(forKey key: NSAnimatablePropertyKey) -> Any? {
        if key == "highlightPosition" { return CABasicAnimation(keyPath: key) }
        return super.defaultAnimation(forKey: key)
    }

    func setModeSelection(_ index: Int, animated: Bool) {
        selectedSegment = index
        guard targetSegment != index else { return }
        let shouldAnimate = animated && targetSegment != nil
        targetSegment = index
        NSAnimationContext.runAnimationGroup { context in
            context.duration = shouldAnimate ? AppTheme.transitionDuration : 0
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().highlightPosition = CGFloat(index)
        }
        // animator 的零时长更新仍可能延迟到下一帧，减少动态效果时立即定位。
        if !shouldAnimate { highlightPosition = CGFloat(index) }
    }

    override func draw(_ dirtyRect: NSRect) {
        let background = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
        NSColor.controlBackgroundColor.withAlphaComponent(0.7).setFill()
        background.fill()
        NSColor.separatorColor.withAlphaComponent(0.4).setStroke()
        background.lineWidth = 1
        background.stroke()
        guard segmentCount > 0 else { return }
        let width = bounds.width / CGFloat(segmentCount)
        drawLabels(width: width, color: isEnabled ? .labelColor : .disabledControlTextColor)
        guard selectedSegment >= 0 else { return }
        let position = targetSegment == nil ? CGFloat(selectedSegment) : highlightPosition
        let highlight = NSRect(x: bounds.minX + position * width, y: bounds.minY,
                               width: width, height: bounds.height).insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(roundedRect: highlight, xRadius: 6, yRadius: 6)
        AppTheme.accentNSColor.withAlphaComponent(isEnabled ? 1 : 0.35).setFill()
        path.fill()
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        drawLabels(width: width, color: isEnabled ? .white : .disabledControlTextColor)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawLabels(width: CGFloat, color: NSColor) {
        for index in 0..<segmentCount {
            let text = (label(forSegment: index) ?? "") as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: color
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: bounds.minX + (CGFloat(index) + 0.5) * width - size.width / 2,
                                  y: bounds.midY - size.height / 2), withAttributes: attributes)
        }
    }

    override var focusRingMaskBounds: NSRect { bounds }
    override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
    }
}
