import WebKit

/// Focus once per activation, including when activation precedes window attachment.
final class FocusedMarkdownWebView: WKWebView {
    private var active = false
    private var needsContentFocus = false

    func setActive(_ value: Bool) {
        guard active != value else { return }
        active = value
        needsContentFocus = value
        if value { requestContentFocus() }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        requestContentFocus()
    }

    func requestContentFocus() {
        guard active && needsContentFocus else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.active, self.needsContentFocus,
                  let window = self.window, window.attachedSheet == nil else { return }
            self.needsContentFocus = !window.makeFirstResponder(self)
        }
    }
}
