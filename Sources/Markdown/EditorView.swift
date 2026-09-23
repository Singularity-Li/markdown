import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    let document: OpenDocument

    func makeCoordinator() -> Coordinator { Coordinator(document: document) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        let text = NSTextView()
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
        text.insertionPointColor = .labelColor
        text.setAccessibilityLabel("Markdown 编辑器")
        text.delegate = context.coordinator
        text.string = document.text
        scroll.documentView = text
        context.coordinator.highlight(text)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let text = scroll.documentView as? NSTextView, !text.hasMarkedText() else { return }
        if text.string != document.text {
            text.string = document.text
            context.coordinator.highlight(text)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        let document: OpenDocument
        init(document: OpenDocument) { self.document = document }
        func textDidChange(_ notification: Notification) {
            guard let text = notification.object as? NSTextView else { return }
            document.text = text.string
            // Do not replace attributes during an active Chinese input composition.
            if !text.hasMarkedText() { highlight(text) }
        }
        func highlight(_ text: NSTextView) {
            guard let storage = text.textStorage else { return }
            let styled = MarkdownSyntax.highlighted(text.string)
            let selections = text.selectedRanges
            storage.beginEditing()
            styled.enumerateAttributes(in: NSRange(location: 0, length: styled.length)) { attributes, range, _ in
                storage.setAttributes(attributes, range: range)
            }
            storage.endEditing()
            text.selectedRanges = selections
            text.typingAttributes = [.font: MarkdownSyntax.baseFont, .foregroundColor: NSColor.labelColor]
        }
    }
}
