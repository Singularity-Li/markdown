import AppKit

enum CodeClipboard {
    static func copy(_ body: Any) {
        guard let payload = body as? [String: Any],
              let text = payload["text"] as? String,
              let html = payload["html"] as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        pasteboard.setString(html, forType: .html)
    }
}
