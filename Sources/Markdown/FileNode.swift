import Foundation
import Observation

/// 目录树节点（可递归、可识别、可观察，供侧栏展示）。
@Observable
final class FileNode: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileNode]?
    var isExpanded = false

    init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }

    /// 按扩展名返回 SF Symbol 图标名。
    var icon: String {
        switch url.pathExtension.lowercased() {
        case "md", "markdown", "mkd", "mdown", "txt", "text": return "doc.text"
        case "png", "jpg", "jpeg", "gif", "heic", "webp", "svg", "tiff", "bmp": return "photo"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz", "dmg", "pkg": return "shippingbox"
        case "swift", "c", "cpp", "h", "hpp", "m", "mm", "js", "ts", "jsx", "tsx",
             "py", "rb", "go", "rs", "java", "kt", "sh", "zsh", "bash", "json",
             "yaml", "yml", "html", "css", "scss", "sql", "plist": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }

    /// 递归扫描目录，目录优先、按名称排序；跳过隐藏文件与 .app/.framework 等包。
    static func scan(_ root: URL) -> FileNode? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        return buildNode(url: root)
    }

    private static func buildNode(url: URL) -> FileNode {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        let directory = exists && isDir.boolValue
        let node = FileNode(url: url, isDirectory: directory)

        let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isPackageKey])
        guard directory, values?.isSymbolicLink != true, values?.isPackage != true else { return node }

        let fm = FileManager.default
        let entries = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])) ?? []
        let sorted = entries.sorted { a, b in
            let aDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let bDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if aDir != bDir { return aDir }
            return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
        }
        node.children = sorted.map { buildNode(url: $0) }
        return node
    }
}