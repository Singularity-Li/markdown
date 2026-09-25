import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    let document: OpenDocument
    let isActive: Bool

    func makeCoordinator() -> Coordinator { Coordinator(document: document) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        let text = FocusedMarkdownTextView()
        text.isRichText = false
        text.allowsUndo = true
        text.drawsBackground = false
        text.isAutomaticQuoteSubstitutionEnabled = false
        text.isAutomaticDashSubstitutionEnabled = false
        text.isAutomaticTextReplacementEnabled = false
        text.isAutomaticSpellingCorrectionEnabled = false
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.autoresizingMask = [.width]
        text.textContainer?.widthTracksTextView = true
        text.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        text.textContainerInset = NSSize(width: 18, height: 16)
        text.font = MarkdownSyntax.baseFont
        text.insertionPointColor = AppTheme.accentNSColor
        text.selectedTextAttributes = [.backgroundColor: AppTheme.accentNSColor.withAlphaComponent(0.25)]
        text.setAccessibilityLabel("Markdown 编辑器")
        text.delegate = context.coordinator
        text.string = document.text
        scroll.documentView = text
        context.coordinator.highlight(text)
        context.coordinator.attach(scroll)
        context.coordinator.setActive(isActive, text: text)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let text = scroll.documentView as? FocusedMarkdownTextView else { return }
        context.coordinator.setActive(isActive, text: text)
        guard !text.hasMarkedText() else { return }
        if text.string != document.text {
            text.string = document.text
            context.coordinator.highlight(text)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        let document: OpenDocument
        private var active = false
        private var adjusting = false
        private weak var scroll: NSScrollView?
        init(document: OpenDocument) { self.document = document }
        deinit { NotificationCenter.default.removeObserver(self) }

        func attach(_ scroll: NSScrollView) {
            self.scroll = scroll
            scroll.contentView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(self, selector: #selector(scrolled),
                name: NSView.boundsDidChangeNotification, object: scroll.contentView)
        }

        @objc private func scrolled() {
            guard active, !adjusting, let scroll,
                  let text = scroll.documentView as? NSTextView,
                  let layout = text.layoutManager, let container = text.textContainer,
                  !text.string.isEmpty else { return }
            let y = max(0, scroll.contentView.bounds.minY - text.textContainerOrigin.y)
            let glyph = layout.glyphIndex(for: NSPoint(x: 0, y: y + 1), in: container)
            guard glyph < layout.numberOfGlyphs else { return }
            document.viewportSourceOffset = Double(layout.characterIndexForGlyph(at: glyph))
        }

        func setActive(_ value: Bool, text: FocusedMarkdownTextView) {
            guard value != active else { return }
            if !value { scrolled() }
            active = value
            if value {
                restorePosition(text)
                DispatchQueue.main.async { [weak self, weak text] in
                    guard let self, self.active, let text else { return }
                    self.restorePosition(text)
                    text.setActive(true)
                }
            } else { text.setActive(false) }
        }

        private func restorePosition(_ text: NSTextView) {
            guard let scroll, let layout = text.layoutManager, let container = text.textContainer else { return }
            adjusting = true
            defer { adjusting = false }
            layout.ensureLayout(for: container)
            let offset = min(max(0, Int(document.viewportSourceOffset)), (text.string as NSString).length)
            let glyph = layout.glyphIndexForCharacter(at: offset)
            let rect = glyph < layout.numberOfGlyphs
                ? layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil) : layout.extraLineFragmentRect
            let y = offset == 0 ? 0 : rect.minY + text.textContainerOrigin.y
            scroll.contentView.scroll(to: NSPoint(x: 0, y: max(0, min(y, text.bounds.height - scroll.contentView.bounds.height))))
            scroll.reflectScrolledClipView(scroll.contentView)
            let selection = text.selectedRange()
            let selectedGlyph = layout.glyphIndexForCharacter(at: min(selection.location, (text.string as NSString).length))
            if selectedGlyph < layout.numberOfGlyphs {
                let caret = layout.lineFragmentRect(forGlyphAt: selectedGlyph, effectiveRange: nil).offsetBy(dx: 0, dy: text.textContainerOrigin.y)
                if !caret.intersects(scroll.contentView.bounds) { text.setSelectedRange(NSRange(location: offset, length: 0)) }
            }
        }
        func textDidChange(_ notification: Notification) {
            guard let text = notification.object as? NSTextView else { return }
            document.text = text.string
            // Do not replace attributes during an active Chinese input composition.
            if !text.hasMarkedText() { highlight(text) }
        }
        func highlight(_ text: NSTextView) {
            guard let storage = text.textStorage else { return }
            let styled = MarkdownSyntax.highlighted(text.string)
            let origin = text.enclosingScrollView?.contentView.bounds.origin
            adjusting = true
            defer { adjusting = false }
            storage.beginEditing()
            styled.enumerateAttributes(in: NSRange(location: 0, length: styled.length)) { attributes, range, _ in
                storage.setAttributes(attributes, range: range)
            }
            storage.endEditing()
            if let container = text.textContainer { text.layoutManager?.ensureLayout(for: container) }
            if let origin, let scroll = text.enclosingScrollView {
                scroll.contentView.scroll(to: origin)
                scroll.reflectScrolledClipView(scroll.contentView)
            }
            text.typingAttributes = [.font: MarkdownSyntax.baseFont, .foregroundColor: NSColor.labelColor]
        }
    }
}

/// Request focus only when an editor becomes active, never on ordinary text updates.
final class FocusedMarkdownTextView: NSTextView {
    private var active = false
    private var needsEditorFocus = false

    func setActive(_ value: Bool) {
        guard value != active else { return }
        active = value
        needsEditorFocus = value
        if value {
            requestEditorFocus()
        } else if window?.firstResponder === self {
            window?.makeFirstResponder(nil)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        requestEditorFocus()
    }

    private func requestEditorFocus() {
        guard active && needsEditorFocus else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.active, self.needsEditorFocus,
                  let window = self.window,
                  window.attachedSheet == nil else { return }
            self.needsEditorFocus = !window.makeFirstResponder(self)
        }
    }
}
