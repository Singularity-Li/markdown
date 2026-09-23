import AppKit
import WebKit

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
let container = NSView(frame: window.contentView!.bounds)
window.contentView = container
let tab = NSButton(title: "标签", target: nil, action: nil)
container.addSubview(tab)
let configuration = WKWebViewConfiguration()
configuration.websiteDataStore = .nonPersistent()
let preview = FocusedMarkdownWebView(frame: container.bounds, configuration: configuration)
var failures = 0
func drain() { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
func check(_ title: String, _ passed: Bool) {
    print("\(passed ? "PASS" : "FAIL"): \(title)")
    if !passed { failures += 1 }
}
func focused() -> Bool {
    guard let responder = window.firstResponder as? NSView else { return false }
    return responder === preview || responder.isDescendant(of: preview)
}
window.makeFirstResponder(tab)
preview.setActive(true)
container.addSubview(preview)
drain()
check("打开预览后焦点进入内容", focused())
window.makeFirstResponder(tab)
preview.setActive(true)
preview.requestContentFocus()
drain()
check("普通更新或加载完成不抢回焦点", window.firstResponder === tab)
preview.setActive(false)
preview.setActive(true)
drain()
check("重新激活预览后焦点进入内容", focused())
preview.setActive(false)
window.makeFirstResponder(tab)
preview.requestContentFocus()
drain()
check("后台预览不抢焦点", window.firstResponder === tab)
preview.setActive(true)
preview.setActive(false)
window.makeFirstResponder(tab)
drain()
check("快速切换取消过期焦点请求", window.firstResponder === tab)
exit(failures == 0 ? 0 : 1)
