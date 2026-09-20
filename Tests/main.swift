import Foundation

var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { failures += 1; print("FAIL: \(message)") }
    else { print("PASS: \(message)") }
}
let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: root) }
let file = root.appendingPathComponent("中文.md")
let next = root.appendingPathComponent("next.md")
try "# 原文".write(to: file, atomically: true, encoding: .utf8)
try "# 下一篇".write(to: next, atomically: true, encoding: .utf8)
let store = DocumentStore()
check(!store.showsSidebar && store.documents.isEmpty, "启动无标签且隐藏侧栏")
store.handleOpen(file)
check(store.selectedURL == file && !store.showsSidebar, "直接打开文件同步选择且不展示侧栏")
store.openFile(root.appendingPathComponent("missing.md"))
check(store.currentURL == file && store.markdownText == "# 原文" && store.documents.count == 1, "打开失败保留现有文档且不新增标签")
let unsupported = root.appendingPathComponent("image.png")
try Data([0, 1, 2]).write(to: unsupported)
store.errorMessage = nil
store.openFile(unsupported)
check(store.currentURL == unsupported && store.activeDocument?.isSupported == false && store.errorMessage == nil,
      "不支持格式进入内容占位且不弹出错误")
check(store.documents.first?.text == "# 原文", "不支持格式保留原 Markdown 标签")
store.updateText("不能编辑")
store.isPreviewMode = false
check(store.markdownText.isEmpty && !store.isDirty && store.isPreviewMode && !store.save(), "不支持格式不能编辑或保存覆盖原文件")
store.close(unsupported)
check(store.currentURL == file && store.documents.count == 1, "关闭不支持格式返回原文档")
store.updateText("# 第一篇未保存")
store.isPreviewMode = false
store.openFile(next)
check(store.documents.count == 2 && store.currentURL == next, "打开第二篇保留第一篇未保存标签")
check(store.markdownText == "# 下一篇" && !store.isDirty && store.isPreviewMode, "新标签拥有独立内容与模式")
store.updateText("# 第二篇未保存")
store.activate(file)
check(store.markdownText == "# 第一篇未保存" && store.isDirty && !store.isPreviewMode, "切回保留第一篇内容和编辑模式")
store.openFile(file)
check(store.documents.count == 2 && store.markdownText == "# 第一篇未保存", "重复打开不新增标签也不覆盖草稿")
let alias = root.appendingPathComponent("alias.md")
try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: file)
store.openFile(alias)
check(store.documents.count == 2 && store.currentURL == file, "同文件符号链接复用已有标签")
check(store.save(), "保存当前标签成功")
let firstSaved = try String(contentsOf: file, encoding: .utf8)
let nextOriginal = try String(contentsOf: next, encoding: .utf8)
check(firstSaved == "# 第一篇未保存" && nextOriginal == "# 下一篇", "保存只写入当前标签对应文件")
check(!store.isDirty && store.documents[1].isDirty, "保存不清除其他标签未保存状态")
store.updateText("改动")
store.updateText("# 第一篇未保存")
check(!store.isDirty, "撤销到保存基线恢复干净状态")
store.confirmClose = { _ in .cancel }
check(!store.close(next) && store.documents.count == 2 && store.currentURL == file, "取消关闭后台脏标签保留所有文档及选择")
var prompted: [URL] = []
store.confirmClose = { document in prompted.append(document.url); return .cancel }
check(!store.canCloseAll() && prompted == [next], "退出会检查后台未保存标签")
store.confirmClose = { _ in .save }
check(store.close(next) && store.documents.count == 1 && store.currentURL == file, "保存并关闭后台标签不切换当前标签")
let secondSaved = try String(contentsOf: next, encoding: .utf8)
check(secondSaved == "# 第二篇未保存", "后台标签保存写入正确文件")
store.handleOpen([file, next, file])
check(store.documents.count == 2 && store.currentURL == file, "批量打开去重并依次激活")
store.openFolder(root)
check(store.showsSidebar && store.folderRoot == root && store.documents.count == 2, "打开目录自动展开且保留全部标签")
store.showsSidebar = false
store.openFolder(root)
check(store.showsSidebar, "重新打开目录自动展开侧栏")
store.select(FileNode(url: next, isDirectory: false))
check(store.folderRoot == root && store.documents.count == 2 && store.currentURL == next, "侧栏选择复用标签并保留导航")
store.handleOpen(file)
check(!store.showsSidebar && store.folderRoot == nil && store.documents.count == 2, "统一入口打开文件隐藏导航但保留标签")
store.handleOpen([next, root])
check(store.showsSidebar && store.folderRoot == root && store.currentURL == next, "混选目录和文件保留目录导航")
store.confirmClose = { _ in .discard }
store.updateText("丢弃内容")
check(store.close(next) && store.currentURL == file, "关闭活动标签选中相邻标签")
let afterDiscard = try String(contentsOf: next, encoding: .utf8)
check(afterDiscard == secondSaved, "不保存关闭不会写入草稿")
check(store.close(file) && store.activeID == nil && store.documents.isEmpty, "关闭最后标签回到空状态")

let quitting = DocumentStore()
quitting.handleOpen([file, next])
quitting.updateText("第二篇退出草稿")
quitting.activate(file)
quitting.updateText("第一篇退出草稿")
var decisions = 0
quitting.confirmClose = { _ in decisions += 1; return decisions == 1 ? .discard : .cancel }
check(!quitting.canCloseAll() && decisions == 2, "退出逐一询问所有脏标签")
check(quitting.documents.allSatisfy { $0.isDirty } && quitting.documents.count == 2, "中途取消退出不丢弃此前选择不保存的草稿")
quitting.confirmClose = { _ in .save }
check(quitting.canCloseAll() && quitting.documents.allSatisfy { !$0.isDirty }, "退出保存所有脏标签")
let broken = root.appendingPathComponent("broken.md")
try "原文".write(to: broken, atomically: true, encoding: .utf8)
quitting.openFile(broken)
quitting.updateText("不可丢失")
try FileManager.default.removeItem(at: broken)
try FileManager.default.createDirectory(at: broken, withIntermediateDirectories: true)
check(!quitting.close(broken) && quitting.currentURL == broken && quitting.isDirty, "保存失败取消关闭且保留草稿")
check(quitting.errorMessage != nil, "保存失败提供错误信息")
let package = root.appendingPathComponent("Example.app")
try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
let link = root.appendingPathComponent("loop")
try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root)
let tree = FileNode.scan(root)
check(tree?.children?.first(where: { $0.url == package })?.children == nil, "不递归应用程序包")
check(tree?.children?.first(where: { $0.url == link })?.children == nil, "目录符号链接不无限递归")
let preferencesSuite = "MarkdownTests-" + UUID().uuidString
let preferences = UserDefaults(suiteName: preferencesSuite)!
defer { preferences.removePersistentDomain(forName: preferencesSuite) }
let appearance = AppearanceSettings(defaults: preferences)
check(appearance.transparency == AppearanceSettings.defaultTransparency, "未设置透明度时使用默认值")
var appliedTransparency: Double?
appearance.onChange = { appliedTransparency = $0 }
appearance.transparency = 0.72
check(appliedTransparency == 0.72, "透明度调整实时通知窗口")
check(AppearanceSettings(defaults: preferences).transparency == 0.72, "新实例读取自动保存的透明度")
appearance.transparency = 2
check(appearance.transparency == 1, "透明度上限有效")
appearance.transparency = -1
check(appearance.transparency == 0, "透明度下限有效")
appearance.transparency = .nan
check(appearance.transparency == AppearanceSettings.defaultTransparency, "异常透明度恢复合理默认值")
exit(failures == 0 ? 0 : 1)
