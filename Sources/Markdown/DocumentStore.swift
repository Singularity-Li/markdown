import Foundation
import Observation

/// 应用全局文档状态（单窗口个人应用，使用单例）。
@Observable
final class DocumentStore {
    static let shared = DocumentStore()

    /// 所有替换文档的入口共享同一未保存确认。
    var confirmReplacement: (() -> Bool)?
    var errorMessage: String?
    private var savedText = ""

    /// 当前已加载的 Markdown 文件 URL（仅加载 .md 时才非 nil）。
    var currentURL: URL?
    /// 当前正文内容。
    var markdownText: String = ""
    /// 是否存在未保存的编辑。
    var isDirty: Bool = false
    /// true = 预览，false = 编辑。
    var isPreviewMode: Bool = true
    var showsSidebar = false
    /// 窗口内拖拽悬停状态（用于高亮提示）。
    var isDropTargeted: Bool = false

    /// 文件夹模式：当前打开目录的根。
    var folderRoot: URL?
    /// 文件夹模式：整棵目录树。
    var folderTree: FileNode?
    /// 当前在侧栏选中的节点 URL（用于高亮，包括非 md 文件）。
    var selectedURL: URL?

    /// 顶部标题。
    var displayTitle: String {
        if let url = currentURL {
            return url.lastPathComponent
        }
        if let folder = folderRoot {
            return folder.lastPathComponent
        }
        return "Markdown"
    }

    /// 是否有真正加载进来的 Markdown 内容（用于判断展示编辑/预览 vs 占位）。
    var hasLoadedDocument: Bool {
        currentURL != nil
    }

    // MARK: - 打开

    /// 根据 URL 区分目录 / 文件，统一入口（菜单、拖拽、Dock 打开都会走这里）。
    func handleOpen(_ url: URL) {
        NSLog("[Markdown] handleOpen: %@", url.path)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            openFolder(url)
        } else if openFile(url) {
            folderRoot = nil
            folderTree = nil
            showsSidebar = false
        }
    }

    /// 打开单个文件：仅 .md / .markdown / .mkd / .mdown 会加载，其它保持右侧空白。
    @discardableResult
    func openFile(_ url: URL) -> Bool {
        guard isMarkdown(url) else {
            errorMessage = "不支持“\(url.lastPathComponent)”。请选择 Markdown 文件。"
            return false
        }
        do {
            var text = try String(contentsOf: url, encoding: .utf8)
            let wasDirty = isDirty
            guard !isDirty || confirmReplacement?() == true else { return false }
            if wasDirty { text = try String(contentsOf: url, encoding: .utf8) }
            markdownText = text
            savedText = text
            currentURL = url
            selectedURL = url
            isDirty = false
            return true
        } catch {
            errorMessage = "无法打开“\(url.lastPathComponent)”：\(error.localizedDescription)"
            return false
        }
    }

    func openFolder(_ url: URL) {
        guard !isDirty || confirmReplacement?() == true else { return }
        guard let tree = FileNode.scan(url) else {
            errorMessage = "无法读取文件夹“\(url.lastPathComponent)”。"
            return
        }
        folderRoot = url
        folderTree = tree
        showsSidebar = true
        currentURL = nil
        markdownText = ""
        savedText = ""
        isDirty = false
        selectedURL = nil
    }

    func select(_ node: FileNode) {
        guard !node.isDirectory else { return }
        openFile(node.url)
    }

    func updateText(_ text: String) {
        markdownText = text
        isDirty = currentURL != nil && text != savedText
    }

    // MARK: - 保存

    @discardableResult
    func save() -> Bool {
        guard let url = currentURL else { return false }
        do {
            try markdownText.write(to: url, atomically: true, encoding: .utf8)
            savedText = markdownText
            isDirty = false
            return true
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 私有

    private func isMarkdown(_ url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "md", "markdown", "mkd", "mdown": return true
        default: return false
        }
    }
}