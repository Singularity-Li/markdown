import AppKit
let app = NSApplication.shared
var failures = 0
func check(_ condition: Bool, _ title: String) {
    print("\(condition ? "PASS" : "FAIL"): \(title)")
    if !condition { failures += 1 }
}
let examples = ["# 中文标题 📝", "标题\n===", "**粗体**", "*斜体*", "~~删除~~", "> 引用", "- [x] 任务", "1. 列表", "[链接](https://example.com)", "![图片](image.png)", "[引用][id]", "[^注释]", "| 表格 |", "<div>HTML</div>", "$x^2$", "---", "`code`", "```swift\nlet x = 1\n```", "~~~\ncode\n~~~", "    code", "&amp;"]
for source in examples {
    let value = MarkdownSyntax.highlighted(source)
    var colored = false
    value.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: value.length)) { color, _, _ in
        if let color = color as? NSColor, color != NSColor.labelColor { colored = true }
    }
    check(value.string == source && colored, "保留源码并高亮：\(source.replacingOccurrences(of: "\n", with: " / "))")
}
let code = MarkdownSyntax.highlighted("```\n# 非标题\n```")
check(code.attribute(.foregroundColor, at: 5, effectiveRange: nil) as? NSColor == .systemBrown, "代码块不误识别标题")
check(MarkdownSyntax.highlighted("").length == 0, "空文档正常")
exit(failures == 0 ? 0 : 1)
