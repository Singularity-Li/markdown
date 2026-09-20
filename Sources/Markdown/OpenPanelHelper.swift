import AppKit

enum OpenPanelHelper {
    /// 同一个面板选择文件或目录，由文档状态统一识别。
    static func openPanel() {
        let panel = NSOpenPanel()
        panel.title = "打开文件或文件夹"
        panel.message = "选择 Markdown 文件直接阅读，或选择文件夹浏览其中的文档"
        panel.prompt = "打开"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            DocumentStore.shared.handleOpen(url)
        }
    }
}
