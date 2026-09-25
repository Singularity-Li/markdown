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
    static func document(markdown: String, sourceOffset: Double = 0) -> String {
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
                var source = b64ToUtf8(\(b64.jsonQuoted));
                var tokens = marked.lexer(source);
                var offset = 0;
                tokens.forEach(function(token) {
                    var found = source.indexOf(token.raw, offset);
                    var start = found >= 0 ? found : offset;
                    offset = start + token.raw.length;
                    var template = document.createElement('template');
                    template.innerHTML = marked.parser([token]);
                    Array.from(template.content.children).forEach(function(node) {
                        node.dataset.sourceStart = start;
                        node.dataset.sourceEnd = offset;
                    });
                    el.appendChild(template.content);
                });
                el.querySelectorAll('li').forEach(function(item) {
                    if (item.querySelector(':scope > input[type="checkbox"], :scope > p > input[type="checkbox"]')) {
                        item.classList.add('task-list-item');
                        item.parentElement.classList.add('contains-task-list');
                    }
                });
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
                var blocks = Array.from(el.children).filter(function(node) { return node.dataset.sourceStart !== undefined; });
                window.mdSourceOffset = function() {
                    var node = blocks.find(function(n) { return n.getBoundingClientRect().bottom > 0; }) || blocks[blocks.length - 1];
                    if (!node) return 0;
                    var rect = node.getBoundingClientRect();
                    var start = Number(node.dataset.sourceStart), end = Number(node.dataset.sourceEnd);
                    return start + (end - start) * Math.max(0, Math.min(1, -rect.top / Math.max(1, rect.height)));
                };
                var restoreOffset = 0;
                window.mdRestoreOffset = function(value) {
                    restoreOffset = value;
                    if (value <= 0) { window.scrollTo(0, 0); return; }
                    var node = blocks.find(function(n) { return Number(n.dataset.sourceEnd) > value; }) || blocks[blocks.length - 1];
                    if (!node) return;
                    var start = Number(node.dataset.sourceStart), end = Number(node.dataset.sourceEnd);
                    var rect = node.getBoundingClientRect();
                    var fraction = Math.max(0, Math.min(1, (value - start) / Math.max(1, end - start)));
                    window.scrollTo(0, Math.max(0, window.scrollY + rect.top + rect.height * fraction));
                };
                var initialOffset = \(sourceOffset.isFinite ? max(0, sourceOffset) : 0);
                window.mdRestoreOffset(initialOffset);
                // 图片加载改变布局时维持初始位置，用户开始操作后不再干预滚动。
                var userScrolled = false;
                ['wheel', 'touchstart', 'keydown', 'pointerdown'].forEach(function(name) {
                    window.addEventListener(name, function() { userScrolled = true; }, {passive:true});
                });
                el.querySelectorAll('img').forEach(function(img) {
                    img.addEventListener('load', function() { if (!userScrolled) window.mdRestoreOffset(restoreOffset); });
                });
                window.addEventListener('scroll', function() {
                    var handler = window.webkit && window.webkit.messageHandlers.viewport;
                    if (handler) handler.postMessage(window.mdSourceOffset());
                }, {passive:true});
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