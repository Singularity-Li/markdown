import Foundation

var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { failures += 1; print("FAIL: \(message)") }
    else { print("PASS: \(message)") }
}
let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: root) }
let file = root.appendingPathComponent("中文.md")
try "# 原文".write(to: file, atomically: true, encoding: .utf8)
let store = DocumentStore()
store.openFile(file)
check(store.selectedURL == file, "直接打开文件同步侧栏选择")
store.openFile(root.appendingPathComponent("missing.md"))
check(store.currentURL == file && store.markdownText == "# 原文", "打开失败保留现有文档")
store.openFile(file)
store.openFile(root.appendingPathComponent("image.png"))
check(store.currentURL == file, "不支持的文件不清空现有文档")
let package = root.appendingPathComponent("Example.app")
try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
try "hidden".write(to: package.appendingPathComponent("internal.md"), atomically: true, encoding: .utf8)
let tree = FileNode.scan(root)
check(tree?.children?.first(where: { $0.url == package })?.children == nil, "不递归扫描应用程序包")
let next = root.appendingPathComponent("next.md")
try "# 下一篇".write(to: next, atomically: true, encoding: .utf8)
store.openFile(file)
store.updateText("# 未保存")
store.confirmReplacement = { false }
store.openFile(next)
check(store.currentURL == file && store.markdownText == "# 未保存" && store.isDirty, "取消切换保留未保存内容")
store.openFolder(root)
check(store.currentURL == file && store.isDirty, "打开文件夹同样保护未保存内容")
store.confirmReplacement = { store.save() }
store.openFile(file)
check(store.markdownText == "# 未保存" && !store.isDirty, "保存并重开同一文件读取最新内容")
store.updateText("# 改动")
store.updateText("# 未保存")
check(!store.isDirty, "撤销到已保存内容恢复干净状态")
let link = root.appendingPathComponent("loop")
try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root)
check(FileNode.scan(root)?.children?.first(where: { $0.url == link })?.children == nil, "目录符号链接不无限递归")
let navigation = DocumentStore()
check(!navigation.showsSidebar, "启动默认隐藏侧栏")
navigation.handleOpen(file)
check(!navigation.showsSidebar && navigation.folderRoot == nil, "统一入口打开文件不展示侧栏")
navigation.handleOpen(root)
check(navigation.showsSidebar && navigation.folderRoot == root, "统一入口打开文件夹自动显示侧栏")
navigation.showsSidebar = false
navigation.handleOpen(root)
check(navigation.showsSidebar, "收起后重新打开文件夹自动展开")
navigation.select(FileNode(url: file, isDirectory: false))
check(navigation.showsSidebar && navigation.folderRoot == root && navigation.currentURL == file, "从目录选择文件保留侧栏")
navigation.updateText("未保存导航测试")
navigation.confirmReplacement = { false }
navigation.handleOpen(next)
check(navigation.showsSidebar && navigation.folderRoot == root && navigation.currentURL == file, "取消打开单文件保留目录与侧栏")
navigation.confirmReplacement = { true }
navigation.handleOpen(next)
check(!navigation.showsSidebar && navigation.folderRoot == nil && navigation.currentURL == next, "统一入口打开单文件切换为无侧栏模式")
navigation.handleOpen(root.appendingPathComponent("missing"))
check(!navigation.showsSidebar && navigation.currentURL == next, "打开失败不改变侧栏模式")
exit(failures == 0 ? 0 : 1)
