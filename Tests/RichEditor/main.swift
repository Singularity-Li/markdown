import AppKit
import WebKit

let application = NSApplication.shared
application.setActivationPolicy(.prohibited)

final class Bridge: NSObject, WKScriptMessageHandler {
    var ready = false
    var error: String?
    var changes: [String] = []
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "ready": ready = true
        case "error": error = String(describing: message.body)
        case "markdownChanged": if let text = message.body as? String { changes.append(text) }
        default: break
        }
    }
}

let bridge = Bridge()
let configuration = WKWebViewConfiguration()
for name in ["ready", "error", "markdownChanged", "viewport", "imageUpload"] {
    configuration.userContentController.add(bridge, name: name)
}
let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 650), configuration: configuration)
let window = NSWindow(contentRect: web.frame, styleMask: [.titled], backing: .buffered, defer: false)
window.contentView = web
window.makeKeyAndOrderFront(nil)
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let javascript = try! String(contentsOf: root.appendingPathComponent("Resources/editor.js"), encoding: .utf8)
let css = try! String(contentsOf: root.appendingPathComponent("Resources/editor.css"), encoding: .utf8)
let source = "# 标题\n\n- [ ] 任务\n\n| A | B |\n| --- | --- |\n| 1 | 2 |"
let encoded = Data(source.utf8).base64EncodedString()
let html = """
<!doctype html><html><head><meta charset="utf-8"><style>\(css)</style></head>
<body><div id="editor"></div><script>\(javascript)</script><script>
window.startMarkdownEditor(new TextDecoder().decode(Uint8Array.from(atob('\(encoded)'), c => c.charCodeAt(0))), 0);
</script></body></html>
"""
web.loadHTMLString(html, baseURL: nil)

func until(_ condition: () -> Bool, seconds: TimeInterval = 8) -> Bool {
    let end = Date().addingTimeInterval(seconds)
    while Date() < end && !condition() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.03))
    }
    return condition()
}

func evaluate(_ script: String) -> Any? {
    var finished = false
    var result: Any?
    web.evaluateJavaScript(script) { value, _ in result = value; finished = true }
    _ = until({ finished })
    return result
}

var failures = 0
func check(_ condition: Bool, _ name: String) {
    print("\(condition ? "PASS" : "FAIL"): \(name)")
    if !condition { failures += 1 }
}
check(until({ bridge.ready }), "离线可视化编辑器启动")
check(bridge.error == nil, "无 JavaScript 初始化错误：\(bridge.error ?? "")")
RunLoop.current.run(until: Date().addingTimeInterval(0.4))
check(bridge.changes.isEmpty, "打开文档不会自行改写 Markdown")
_ = evaluate("document.querySelector('.ProseMirror').dispatchEvent(new PointerEvent('pointerdown', {bubbles:true}))")
RunLoop.current.run(until: Date().addingTimeInterval(0.25))
check(bridge.changes.isEmpty, "仅聚焦编辑器不会改写 Markdown")
check((evaluate("document.querySelectorAll('.ProseMirror h1').length") as? Int) == 1, "标题直接排版")
check((evaluate("document.querySelectorAll('.ProseMirror table.children').length") as? Int) == 1, "表格直接排版")
check((evaluate("document.querySelectorAll('.ProseMirror .unchecked').length") as? Int ?? 0) > 0, "复选框直接排版")
_ = evaluate("(function(){ var p=document.querySelector('.ProseMirror > p:last-child'); var r=document.createRange(); r.selectNodeContents(p); r.collapse(true); var s=getSelection(); s.removeAllRanges(); s.addRange(r); document.querySelector('.ProseMirror').focus(); return document.execCommand('insertText',false,'/'); })()")
check(until({ (evaluate("document.body.innerText.includes('文字与标题')") as? Bool) == true }, seconds: 2), "斜线菜单显示分类")
check((evaluate("document.body.innerText.includes('列表与任务') && document.body.innerText.includes('插入内容')") as? Bool) == true, "斜线菜单包含列表和插入分类")
check((evaluate("document.body.innerText.includes('行内格式') && document.body.innerText.includes('行内代码')") as? Bool) == true, "斜线菜单包含行内格式分类")
check(until({ bridge.changes.contains(where: { $0.contains("/") }) }, seconds: 2), "编辑内容写回 Markdown")
_ = evaluate("document.execCommand('insertText', false, '代码')")
check(until({ (evaluate("document.body.innerText.includes('代码块')") as? Bool) == true }, seconds: 2), "输入中文可筛选斜线命令")
_ = evaluate("(function(){ var el=Array.from(document.querySelectorAll('.milkdown-slash-menu li')).find(el => el.textContent.trim() === '代码块'); el?.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true})); el?.dispatchEvent(new PointerEvent('pointerup', {bubbles:true})); })()")
check(until({ bridge.changes.last?.contains("```") == true }, seconds: 2), "斜线命令插入可保存的代码块")
web.appearance = NSAppearance(named: .darkAqua)
check(until({ (evaluate("matchMedia('(prefers-color-scheme: dark)').matches") as? Bool) == true }, seconds: 2), "编辑区跟随系统深色外观")
check((evaluate("getComputedStyle(document.querySelector('.milkdown')).getPropertyValue('--crepe-color-on-surface').trim()") as? String) == "#eee", "深色外观文字保持可读")
check((evaluate("typeof window.markdownImageUploadResult") as? String) == "function", "图片上传回调可用")
bridge.ready = false
bridge.changes.removeAll()
web.loadHTMLString(html.replacingOccurrences(of: encoded, with: ""), baseURL: nil)
check(until({ bridge.ready }), "空白可视化文档启动")
_ = evaluate("(function(){ var p=document.querySelector('.ProseMirror > p:last-child'); var r=document.createRange(); r.selectNodeContents(p); r.collapse(true); var s=getSelection(); s.removeAllRanges(); s.addRange(r); document.querySelector('.ProseMirror').focus(); return document.execCommand('insertText',false,'/'); })()")
check(until({ (evaluate("document.querySelector('.milkdown-slash-menu')?.getAttribute('data-show') === 'true'") as? Bool) == true }, seconds: 2), "空白文档斜线菜单打开")
_ = evaluate("(function(){ var el=Array.from(document.querySelectorAll('.milkdown-slash-menu .menu-groups li')).find(el => el.querySelector('span:last-child')?.textContent === '加粗'); el?.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true})); el?.dispatchEvent(new PointerEvent('pointerup', {bubbles:true})); return document.execCommand('insertText',false,'文字'); })()")
check(until({ bridge.changes.last?.contains("**文字**") == true }, seconds: 2), "行内格式命令写出粗体 Markdown")
bridge.ready = false
bridge.changes.removeAll()
web.loadHTMLString(html.replacingOccurrences(of: encoded, with: ""), baseURL: nil)
check(until({ bridge.ready }), "链接测试文档启动")
_ = evaluate("(function(){ var p=document.querySelector('.ProseMirror > p:last-child'); var r=document.createRange(); r.selectNodeContents(p); r.collapse(true); var s=getSelection(); s.removeAllRanges(); s.addRange(r); document.querySelector('.ProseMirror').focus(); return document.execCommand('insertText',false,'/'); })()")
check(until({ (evaluate("document.querySelector('.milkdown-slash-menu')?.getAttribute('data-show') === 'true'") as? Bool) == true }, seconds: 2), "链接命令菜单打开")
_ = evaluate("(function(){ var el=Array.from(document.querySelectorAll('.milkdown-slash-menu .menu-groups li')).find(el => el.querySelector('span:last-child')?.textContent === '链接'); el?.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true})); el?.dispatchEvent(new PointerEvent('pointerup', {bubbles:true})); return document.execCommand('insertText',false,'文字'); })()")
check(until({ bridge.changes.last?.contains("[文字](https://)") == true }, seconds: 2), "链接命令写出 Markdown 链接")
exit(failures == 0 ? 0 : 1)
