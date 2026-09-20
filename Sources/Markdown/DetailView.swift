import SwiftUI

struct DetailView: View {
    let store: DocumentStore
    var toggleSidebar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.2)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

    }

    private var previewBinding: Binding<Bool> {
        Binding(get: { store.isPreviewMode }, set: { store.isPreviewMode = $0 })
    }

    // MARK: - 顶栏（左侧标题，右上角原生开关）

    private var header: some View {
        HStack(spacing: 10) {
            if store.folderRoot != nil {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
                .buttonStyle(.glass)
                .help(store.showsSidebar ? "收起侧栏" : "展开侧栏")
                .accessibilityLabel(store.showsSidebar ? "收起侧栏" : "展开侧栏")
            }

            Label(store.displayTitle + (store.isDirty ? " · 未保存" : ""), systemImage: "doc.text")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.leading, 4)

            Spacer()

            Button {
                OpenPanelHelper.openPanel()
            } label: {
                Label("打开", systemImage: "folder")
            }
            .buttonStyle(.glass)
            .help("打开 Markdown 文件或文件夹 (⌘O)")
            .accessibilityLabel("打开文件或文件夹")

            Toggle(isOn: previewBinding) {
                Text("预览")
            }
            .toggleStyle(.switch)
            .controlSize(.large)
            .help("切换 预览 / 编辑")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - 内容区

    @ViewBuilder
    private var content: some View {
        if store.hasLoadedDocument {
            if store.isPreviewMode {
                PreviewView(
                    markdown: store.markdownText,
                    baseURL: store.currentURL?.deletingLastPathComponent()
                )
            } else {
                EditorView(store: store)
                    .id(store.currentURL)
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: placeholderIcon)
                .font(.system(size: 46))
                .foregroundStyle(.secondary)
            Text(placeholderText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholderIcon: String {
        if store.selectedURL != nil { return "doc.text.magnifyingglass" }
        if store.folderRoot != nil { return "list.bullet.rectangle" }
        return "square.and.arrow.down.on.square"
    }

    private var placeholderText: String {
        if store.selectedURL != nil { return "此文件类型不受支持" }
        if store.folderRoot != nil { return store.showsSidebar ? "从左侧选择一个 Markdown 文件" : "展开侧栏以选择 Markdown 文件" }
        return "将 Markdown 文件或文件夹拖到这里\n或使用右上角按钮打开"
    }
}