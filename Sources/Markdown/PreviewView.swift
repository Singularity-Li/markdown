import SwiftUI
import WebKit

/// 用 WKWebView 渲染 Markdown（marked + highlight.js，全部内嵌离线，无网络依赖）。
struct PreviewView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    let isActive: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(context.coordinator.images, forURLScheme: "md-image")
        let webView = FocusedMarkdownWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) {
            webView.underPageBackgroundColor = .clear
        }
        // 关键：禁止 WKWebView 拦截文件拖放（否则拖文件到预览区会被当成网页导航）。
        webView.unregisterDraggedTypes()
        webView.navigationDelegate = context.coordinator
        webView.setActive(isActive)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        (webView as? FocusedMarkdownWebView)?.setActive(isActive)
        let key = (baseURL?.path ?? "<no-base>") + "\u{0}" + markdown
        guard context.coordinator.key != key else { return }
        context.coordinator.key = key
        context.coordinator.images.directory = baseURL
        // baseURL = 文件所在目录，用于解析相对路径的图片等资源。
        webView.loadHTMLString(MarkdownHTML.document(markdown: markdown), baseURL: baseURL)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var key = ""
        let images = LocalImageHandler()

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow); return
            }
            if url.fragment != nil, url.deletingFragment == webView.url?.deletingFragment {
                decisionHandler(.allow); return
            }
            decisionHandler(.cancel)
            if url.isFileURL {
                DocumentStore.shared.handleOpen(url)
            } else if ["https", "http", "mailto"].contains(url.scheme?.lowercased() ?? "") {
                NSWorkspace.shared.open(url)
            }
        }


        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            (webView as? FocusedMarkdownWebView)?.requestContentFocus()
            // 静默诊断：只有渲染结果为空或捕获到 JS 错误时才打日志。
            webView.evaluateJavaScript(
                "(function(){" +
                "var el = document.getElementById('content');" +
                "var errs = (window.__mdErrors || []).join('|');" +
                "var len = el ? el.innerHTML.length : -1;" +
                "if (len === 0 || errs) { return 'len=' + len + ' errors=' + errs; }" +
                "return null;" +
                "})()"
            ) { result, _ in
                if let problem = result as? String {
                    NSLog("[Markdown] 预览渲染异常: \(problem)")
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            NSLog("[Markdown] 预览加载失败: \(error.localizedDescription)")
        }
    }
}
private extension URL {
    var deletingFragment: URL? {
        var parts = URLComponents(url: self, resolvingAgainstBaseURL: true)
        parts?.fragment = nil
        return parts?.url
    }
}
