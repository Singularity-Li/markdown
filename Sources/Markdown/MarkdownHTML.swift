import Foundation

extension String {
    /// 生成合法的 JS 字符串字面量（含首尾引号）。
    var jsonQuoted: String {
        let data = (try? JSONSerialization.data(withJSONObject: [self])) ?? Data("[]".utf8)
        let text = String(data: data, encoding: .utf8) ?? "[]"
        // ["..."] -> "..."
        return String(text.dropFirst().dropLast())
    }
}

/// 组装离线渲染 Markdown 的完整 HTML 文档。
enum MarkdownHTML {
    static func document(markdown: String) -> String {
        // 正文用 base64 传入，彻底规避 </script>、引号、反斜杠等转义问题。
        let b64 = Data(markdown.utf8).base64EncodedString()
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>\(Assets.styleCSS)</style>
        </head>
        <body>
        <article id="content" class="markdown-body"></article>
        <script>
        (function () {
            window.__mdErrors = [];
            window.onerror = function (m) { try { window.__mdErrors.push(String(m)); } catch (e) {} };
        })();
        </script>
        <script>\(Assets.markedJS)</script>
        <script>\(Assets.highlightJS)</script>
        <script>
        (function () {
            function b64ToUtf8(b64) {
                var bin = atob(b64);
                var bytes = Uint8Array.from(bin, function (c) { return c.charCodeAt(0); });
                return new TextDecoder().decode(bytes);
            }
            try {
                marked.setOptions({ gfm: true, breaks: false });
                var el = document.getElementById('content');
                el.innerHTML = marked.parse(b64ToUtf8(\(b64.jsonQuoted)));
                // Preserve authored anchors and reserve their names before generating heading IDs.
                var used = new Set(Array.from(el.querySelectorAll('[id],a[name]')).map(function (node) { return node.id || node.getAttribute('name'); }));
                el.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(function (heading) {
                    if (heading.id) return;
                    var slug = heading.textContent.toLowerCase().trim().replace(/[^\\p{L}\\p{N}_\\s-]/gu, '').replace(/\\s/g, '-');
                    var id = slug, n = 1;
                    while (used.has(id)) id = slug + '-' + n++;
                    used.add(id); heading.id = id;
                });
                el.querySelectorAll('img').forEach(function (img) {
                    var url = new URL(img.getAttribute('src'), document.baseURI);
                    if (url.protocol === 'file:') {
                        img.src = 'md-image://local' + url.pathname;
                    }
                });
                try {
                    document.querySelectorAll('pre code').forEach(function (b) { hljs.highlightElement(b); });
                } catch (e2) { window.__mdErrors.push('hljs: ' + e2); }
            } catch (e) {
                window.__mdErrors.push('render: ' + (e && e.stack ? e.stack : String(e)));
            }
        })();
        </script>
        </body>
        </html>
        """
    }
}