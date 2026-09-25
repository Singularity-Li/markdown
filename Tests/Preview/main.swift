import AppKit
import WebKit

// Exercise the real generated HTML in WebKit, including Markdown parsing and DOM IDs.
final class PreviewCheck: NSObject, WKNavigationDelegate {
    var finished = false
    var failures = 0
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("""
        (() => {
            const content = document.getElementById('content');
            const headings = Array.from(content.querySelectorAll('h2'));
            const checkbox = content.querySelector('input[type="checkbox"]');
            const target = Array.from(content.querySelectorAll('h2')).find(n => n.textContent === '位置 50');
            const offset = Number(target.dataset.sourceStart);
            window.mdRestoreOffset(offset);
            const positionMatches = Math.abs(window.mdSourceOffset() - offset) < 2 && window.scrollY > 1000;
            window.mdRestoreOffset(0);
            return [
                ['恢复文档顶部没有额外偏移', window.scrollY === 0],
                ['引用式链接正常渲染', content.querySelector('a[href="https://example.com"]') !== null],
                ['复选框具有清晰的18像素尺寸', checkbox.getBoundingClientRect().width >= 18 && checkbox.getBoundingClientRect().height >= 18],
                ['任务复选框没有重复列表圆点', getComputedStyle(checkbox.closest('li')).listStyleType === 'none'],
                ['链接使用常规蓝色', ['rgb(9, 105, 218)', 'rgb(88, 166, 255)'].includes(getComputedStyle(content.querySelector('a')).color)],
                ['预览中部位置可从源码偏移恢复并读回', positionMatches],
                ['宽窗口正文填满可用宽度', Math.abs(content.getBoundingClientRect().width - document.documentElement.clientWidth) < 2],
                ['预览左右边距保持紧凑', parseFloat(getComputedStyle(content).paddingLeft) <= 18],
                ['保留中文自定义锚点', headings[0].id === 'zh'],
                ['保留英文自定义锚点', headings[1].id === 'en'],
                ['自动标题避开显式 ID', headings[2].id === 'english-1'],
                ['重复标题生成唯一锚点', headings[3].id === 'english-2'],
                ['中英文链接均有目标', Array.from(content.querySelectorAll('a[href^="#"]')).every(a => document.getElementById(decodeURIComponent(a.hash.slice(1))))],
                ['渲染无脚本错误', window.__mdErrors.length === 0]
            ];
        })()
        """) { result, error in
            if let checks = result as? [[Any]] {
                for check in checks {
                    let passed = check[1] as? Bool == true
                    print("\(passed ? "PASS" : "FAIL"): \(check[0])")
                    if !passed { self.failures += 1 }
                }
            } else {
                print("FAIL: WebKit检查失败 \(String(describing: error))")
                self.failures += 1
            }
            self.finished = true
        }
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let checker = PreviewCheck()
let configuration = WKWebViewConfiguration()
configuration.websiteDataStore = .nonPersistent()
let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1400, height: 600), configuration: configuration)
webView.navigationDelegate = checker
webView.loadHTMLString(MarkdownHTML.document(markdown: """
[中文](#zh) | [English](#en)

<h2 id="zh">中文内容</h2>
<h2 id="en">English content</h2>
<a id="english"></a>

## English

## English

- [ ] 待办
- [x] 完成

[参考][reference]

[reference]: https://example.com
""" + (1...100).map { "\n\n## 位置 \($0)\n\n中文与 emoji 👋 正文 \($0)\n\n一段额外内容。" }.joined()), baseURL: URL(fileURLWithPath: NSTemporaryDirectory()))
let deadline = Date().addingTimeInterval(20)
while !checker.finished && Date() < deadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
}
if !checker.finished { print("FAIL: WebKit 渲染超时"); exit(1) }
exit(checker.failures == 0 ? 0 : 1)
