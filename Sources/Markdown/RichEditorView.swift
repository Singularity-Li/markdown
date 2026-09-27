import SwiftUI
import WebKit
import UniformTypeIdentifiers

/// An offline Markdown document editor. Markdown remains the document's only saved format.
struct RichEditorView: NSViewRepresentable {
    let document: OpenDocument
    let isActive: Bool

    func makeCoordinator() -> Coordinator { Coordinator(document: document) }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let messages = configuration.userContentController
        for name in Coordinator.messageNames { messages.add(context.coordinator, name: name) }
        configuration.setURLSchemeHandler(context.coordinator.images, forURLScheme: "md-image")
        let webView = FocusedMarkdownWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.underPageBackgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        webView.unregisterDraggedTypes()
        webView.setActive(isActive)
        context.coordinator.load(document: document, in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        let becameActive = isActive && !coordinator.active
        coordinator.active = isActive
        (webView as? FocusedMarkdownWebView)?.setActive(isActive)
        guard isActive else { return }
        let key = coordinator.documentKey(document)
        if key != coordinator.key {
            coordinator.load(document: document, in: webView)
        } else if becameActive && coordinator.ready {
            webView.evaluateJavaScript("window.markdownEditorFocus()")
        }
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        for name in Coordinator.messageNames {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        static let messageNames = ["markdownChanged", "viewport", "imageUpload", "ready", "error"]
        let document: OpenDocument
        let images = LocalImageHandler()
        var key = ""
        var active = false
        var ready = false

        init(document: OpenDocument) { self.document = document }

        func documentKey(_ document: OpenDocument) -> String {
            (document.url?.deletingLastPathComponent().path ?? "") + "\u{0}" + document.text
        }

        func load(document: OpenDocument, in webView: WKWebView) {
            key = documentKey(document)
            ready = false
            images.directory = document.url?.deletingLastPathComponent()
            webView.loadHTMLString(RichEditorHTML.document(markdown: document.text,
                                                           sourceOffset: document.viewportSourceOffset),
                                   baseURL: document.url?.deletingLastPathComponent())
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "markdownChanged":
                guard let value = message.body as? String else { return }
                document.text = value
                key = documentKey(document)
            case "viewport":
                guard active, let value = message.body as? NSNumber else { return }
                document.viewportSourceOffset = max(0, min(Double((document.text as NSString).length), value.doubleValue))
            case "imageUpload":
                uploadImage(message.body, in: message.webView)
            case "ready":
                ready = true
                if active {
                    message.webView?.evaluateJavaScript("window.markdownEditorFocus()")
                }
            case "error":
                if let error = message.body as? String { NSLog("[Markdown] 可视化编辑器：%@", error) }
            default: break
            }
        }

        private func uploadImage(_ body: Any, in webView: WKWebView?) {
            guard let body = body as? [String: Any], let id = body["id"] as? Int else { return }
            do {
                guard let directory = document.url?.deletingLastPathComponent() else {
                    throw UploadError.message("请先保存 Markdown 文档，再插入本地图片。")
                }
                guard let name = body["name"] as? String,
                      let encoded = body["data"] as? String,
                      let data = Data(base64Encoded: encoded), data.count <= 20_000_000,
                      let type = UTType(filenameExtension: (name as NSString).pathExtension),
                      type.conforms(to: .image), NSImage(data: data) != nil else {
                    throw UploadError.message("图片无效或超过 20 MB。")
                }
                let assetDirectory = directory.appendingPathComponent("assets", isDirectory: true)
                try FileManager.default.createDirectory(at: assetDirectory, withIntermediateDirectories: true)
                let stem = String(URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent.prefix(60))
                    .replacingOccurrences(of: #"[^\p{L}\p{N}._-]+"#, with: "-", options: .regularExpression)
                let filename = "\(stem)-\(UUID().uuidString.prefix(8)).\(type.preferredFilenameExtension ?? "png")"
                let target = assetDirectory.appendingPathComponent(filename)
                try data.write(to: target, options: .atomic)
                images.directory = directory
                respondToUpload(id: id, path: "assets/\(filename)", error: nil, in: webView)
            } catch {
                DocumentStore.shared.errorMessage = error.localizedDescription
                respondToUpload(id: id, path: nil, error: error.localizedDescription, in: webView)
            }
        }

        private func respondToUpload(id: Int, path: String?, error: String?, in webView: WKWebView?) {
            let script = "window.markdownImageUploadResult(\(id), \((path ?? "").jsonQuoted), \((error ?? "").jsonQuoted))"
            webView?.evaluateJavaScript(script)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow); return
            }
            decisionHandler(.cancel)
            if url.isFileURL { DocumentStore.shared.handleOpen(url) }
            else if ["https", "http", "mailto"].contains(url.scheme?.lowercased() ?? "") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

private enum UploadError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

enum RichEditorHTML {
    static func document(markdown: String, sourceOffset: Double) -> String {
        let resources = Bundle.main.resourceURL ?? URL(fileURLWithPath: "Resources")
        let javascript = (try? String(contentsOf: resources.appendingPathComponent("editor.js"), encoding: .utf8)) ?? ""
        let css = (try? String(contentsOf: resources.appendingPathComponent("editor.css"), encoding: .utf8)) ?? ""
        let base64 = Data(markdown.utf8).base64EncodedString()
        return """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>\(css)</style></head><body><div id="editor"></div>
        <script>\(javascript)</script><script>
        (function(){
          var bytes = Uint8Array.from(atob(\(base64.jsonQuoted)), function(c){ return c.charCodeAt(0); });
          window.startMarkdownEditor(new TextDecoder().decode(bytes), \(sourceOffset.isFinite ? max(0, sourceOffset) : 0));
        })();
        </script></body></html>
        """
    }
}
