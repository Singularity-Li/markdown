import AppKit

enum OpenPanelHelper {
    /// 同一个面板选择文件或目录，由文档状态统一识别。
    static func openPanel() {
        let panel = NSOpenPanel()
        panel.title = "打开文件或文件夹"
        panel.message = "可多选 Markdown 文件在标签页中打开，或选择文件夹浏览"
        panel.prompt = "打开"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            DocumentStore.shared.handleOpen(panel.urls)
        }
    }
}
