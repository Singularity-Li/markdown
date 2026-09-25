import AppKit
import SwiftUI
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let document = OpenDocument(text: (1...300).map { "第\($0)行 中文 English 👋\n" }.joined())
let host = NSHostingView(rootView: EditorView(document: document, isActive: true))
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
window.contentView = host
host.layoutSubtreeIfNeeded()
RunLoop.current.run(until: Date().addingTimeInterval(0.1))
func findText(_ view: NSView) -> NSTextView? {
    if let text = view as? NSTextView { return text }
    return view.subviews.compactMap(findText).first
}
let text = findText(host)!
let scroll = text.enclosingScrollView!
let range = (text.string as NSString).range(of: "第150行")
text.setSelectedRange(NSRange(location: range.location, length: 0))
text.scrollRangeToVisible(text.selectedRange())
RunLoop.current.run(until: Date().addingTimeInterval(0.05))
var failures = 0
func check(_ passed: Bool, _ message: String) {
    print("\(passed ? "PASS" : "FAIL"): \(message)")
    if !passed { failures += 1 }
}
let originalY = scroll.contentView.bounds.minY
check(originalY > 1000, "长文档编辑器已定位中部")
for _ in 0..<5 {
    let before = scroll.contentView.bounds.minY
    text.insertNewline(nil)
    RunLoop.current.run(until: Date().addingTimeInterval(0.03))
    check(abs(scroll.contentView.bounds.minY - before) < 35, "回车与高亮更新不会产生大幅滚动")
}
text.insertText("新增中文 👋", replacementRange: text.selectedRange())
check(document.text.contains("新增中文 👋"), "中文及emoji输入写回文档")
let coordinator = EditorView.Coordinator(document: document)
coordinator.attach(scroll)
document.viewportSourceOffset = Double(range.location)
coordinator.setActive(true, text: text as! FocusedMarkdownTextView)
RunLoop.current.run(until: Date().addingTimeInterval(0.05))
let restoredY = scroll.contentView.bounds.minY
check(restoredY > 1000, "编辑器按共享源码位置恢复到文档中部")
coordinator.setActive(false, text: text as! FocusedMarkdownTextView)
coordinator.setActive(true, text: text as! FocusedMarkdownTextView)
RunLoop.current.run(until: Date().addingTimeInterval(0.05))
check(abs(scroll.contentView.bounds.minY - restoredY) < 25, "连续激活保持位置且不返回开头")
exit(failures == 0 ? 0 : 1)
