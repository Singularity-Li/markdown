import Foundation
import Observation

/// 每个标签独立拥有正文、保存基线和阅读模式。
@Observable
final class OpenDocument: Identifiable {
    let url: URL
    var id: URL { url }
    var text: String
    var savedText: String
    let isSupported: Bool
    var isPreviewMode = true
    var isDirty: Bool { isSupported && text != savedText }

    init(url: URL, text: String, isSupported: Bool = true) {
        self.url = url
        self.isSupported = isSupported
        self.text = text
        self.savedText = text
    }
}

enum CloseDecision { case save, discard, cancel }

@Observable
final class DocumentStore {
    static let shared = DocumentStore()

    private(set) var documents: [OpenDocument] = []
    private(set) var activeID: URL?
    var confirmClose: ((OpenDocument) -> CloseDecision)?
    var errorMessage: String?
    var showsSidebar = false
    var showsAppearancePopover = false
    var isDropTargeted = false
    var folderRoot: URL?
    var folderTree: FileNode?

    var activeDocument: OpenDocument? { documents.first { $0.id == activeID } }
    var currentURL: URL? { activeDocument?.url }
    var selectedURL: URL? { currentURL }
    var markdownText: String { activeDocument?.text ?? "" }
    var isDirty: Bool { activeDocument?.isDirty ?? false }
    var isPreviewMode: Bool {
        get { activeDocument?.isPreviewMode ?? true }
        set {
            guard let document = activeDocument, document.isSupported else { return }
            document.isPreviewMode = newValue
        }
    }
    var displayTitle: String { currentURL?.lastPathComponent ?? folderRoot?.lastPathComponent ?? "Markdown" }
    var hasLoadedDocument: Bool { activeDocument != nil }

    func handleOpen(_ url: URL) { handleOpen([url]) }

    /// 文件多选、Finder、拖放共用此入口；混选时先设置目录，再打开文件。
    func handleOpen(_ urls: [URL]) {
        var folders: [URL] = []
        var files: [URL] = []
        for url in urls {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                folders.append(url)
            } else {
                files.append(url)
            }
        }
        for folder in folders { openFolder(folder) }
        var openedFile = false
        for file in files { if openFile(file) { openedFile = true } }
        if folders.isEmpty && openedFile {
            folderRoot = nil
            folderTree = nil
            showsSidebar = false
        }
    }

    @discardableResult
    func openFile(_ url: URL) -> Bool {
        let canonical = url.standardizedFileURL.resolvingSymlinksInPath()
        if let document = documents.first(where: { $0.id == canonical }) {
            activate(document.id)
            return true
        }
        guard ["md", "markdown", "mkd", "mdown"].contains(url.pathExtension.lowercased()) else {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: canonical.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                errorMessage = "无法打开“\(url.lastPathComponent)”：文件不存在。"
                return false
            }
            let document = OpenDocument(url: canonical, text: "", isSupported: false)
            documents.append(document)
            activate(document.id)
            return true
        }
        do {
            let text = try String(contentsOf: canonical, encoding: .utf8)
            let document = OpenDocument(url: canonical, text: text)
            documents.append(document)
            activate(document.id)
            return true
        } catch {
            errorMessage = "无法打开“\(url.lastPathComponent)”：\(error.localizedDescription)"
            return false
        }
    }

    func openFolder(_ url: URL) {
        guard let tree = FileNode.scan(url) else {
            errorMessage = "无法读取文件夹“\(url.lastPathComponent)”。"
            return
        }
        folderRoot = url
        folderTree = tree
        showsSidebar = true
        // 打开目录只改变导航，不关闭任何已打开的标签。
    }

    func select(_ node: FileNode) {
        guard !node.isDirectory else { return }
        openFile(node.url)
    }

    func activate(_ id: URL) {
        guard documents.contains(where: { $0.id == id }) else { return }
        activeID = id
    }

    func updateText(_ text: String) {
        guard let document = activeDocument, document.isSupported else { return }
        document.text = text
    }

    @discardableResult
    func save() -> Bool {
        guard let document = activeDocument else { return false }
        return save(document)
    }

    @discardableResult
    func save(_ document: OpenDocument) -> Bool {
        guard document.isSupported else { return false }
        do {
            try document.text.write(to: document.url, atomically: true, encoding: .utf8)
            document.savedText = document.text
            return true
        } catch {
            errorMessage = "无法保存“\(document.url.lastPathComponent)”：\(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func close(_ id: URL) -> Bool {
        guard let index = documents.firstIndex(where: { $0.id == id }),
              mayClose(documents[index]) else { return false }
        documents.remove(at: index)
        if activeID == id {
            activeID = documents.isEmpty ? nil : documents[min(index, documents.count - 1)].id
        }
        return true
    }

    /// 逐一检查所有脏标签，包括后台标签。取消时不丢弃任何尚未保存的正文。
    func canCloseAll() -> Bool {
        for document in documents where document.isDirty {
            if !mayClose(document) { return false }
        }
        return true
    }

    private func mayClose(_ document: OpenDocument) -> Bool {
        guard document.isDirty else { return true }
        switch confirmClose?(document) ?? .cancel {
        case .save: return save(document)
        case .discard: return true
        case .cancel: return false
        }
    }
}
