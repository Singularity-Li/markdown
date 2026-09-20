import WebKit
import UniformTypeIdentifiers

/// WKWebView 的 HTML 字符串没有文件读取授权；按文档目录提供图片资源。
final class LocalImageHandler: NSObject, WKURLSchemeHandler {
    var directory: URL?

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url, let directory else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        let file = URL(fileURLWithPath: url.path).resolvingSymlinksInPath()
        let root = directory.resolvingSymlinksInPath().path + "/"
        guard file.path.hasPrefix(root),
              let type = UTType(filenameExtension: file.pathExtension), type.conforms(to: .image),
              let data = try? Data(contentsOf: file) else {
            urlSchemeTask.didFailWithError(URLError(.noPermissionsToReadFile)); return
        }
        urlSchemeTask.didReceive(URLResponse(url: url, mimeType: type.preferredMIMEType,
                                             expectedContentLength: data.count, textEncodingName: nil))
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
