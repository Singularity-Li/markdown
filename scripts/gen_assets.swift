// 将 Resources/ 下的 JS/CSS 内嵌为 Sources/Markdown/Assets.swift 中的 Swift 字符串。
// 用法：swift scripts/gen_assets.swift
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let res = root.appendingPathComponent("Resources")
let out = root.appendingPathComponent("Sources/Markdown/Assets.swift")

func read(_ name: String) throws -> String {
    try String(contentsOf: res.appendingPathComponent(name), encoding: .utf8)
}

let marked = try read("marked.min.js")
let highlight = try read("highlight.min.js")
let css = try read("style.css")

let delim = "######"

func rawLiteral(_ content: String) -> String {
    let terminator = "\"\"\"" + delim
    if content.contains(terminator) {
        fatalError("资源中包含 raw-string 结束符，请加大分隔符长度")
    }
    // 结束定界符放在第 0 列（不缩进），内容亦为第 0 列，避免多行字符串缩进冲突。
    return "    " + delim + "\"\"\"\n" + content + "\n\"\"\"" + delim
}

var file = ""
file += "// 由 scripts/gen_assets.swift 生成 —— 请勿手工编辑。\n"
file += "import Foundation\n\n"
file += "enum Assets {\n"
file += "    static let markedJS = " + rawLiteral(marked) + "\n\n"
file += "    static let highlightJS = " + rawLiteral(highlight) + "\n\n"
file += "    static let styleCSS = " + rawLiteral(css) + "\n"
file += "}\n"

try file.write(to: out, atomically: true, encoding: .utf8)
print("已生成 \(out.path)（\(file.count) 字节）")