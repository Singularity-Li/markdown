import SwiftUI
import AppKit

struct DetailView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let store: DocumentStore

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let document = store.activeDocument, document.isSupported {
                HStack {
                    Spacer()
                    Text("\(document.characterCount.formatted()) 字符 · \(document.lineCount.formatted()) 行")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .help("当前文档字符数：不含空白和换行，包含标点及 Markdown 标记。行数按文本换行统计，包含末尾空行，不计自动折行；空文档为 1 行。")
                        .accessibilityLabel("当前文档共 \(document.characterCount) 个非空白字符，\(document.lineCount) 行")
                }
                .padding(.horizontal, 16)
                .frame(height: 22)
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: store.activeID) { _, _ in
                // 不支持的文件没有正文视图接收焦点，清除后台编辑器焦点。
                if store.activeDocument?.isSupported != true {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            }
    }

    // MARK: - 内容区

    @ViewBuilder
    private var content: some View {
        if store.hasLoadedDocument {
            // 为每个标签保留视图身份，切换不丢失编辑器撤销栈和滚动位置。
            ZStack {
                ForEach(store.documents) { document in
                    Group {
                        if !document.isSupported {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.questionmark")
                                    .font(.system(size: 42))
                                Text("暂不支持此文件格式")
                                    .font(.headline)
                                Text(document.displayName)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                Text("请选择 .md、.markdown、.mkd 或 .mdown 文件")
                                    .font(.callout)
                            }
                            .foregroundStyle(.secondary)
                            .padding(24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ZStack {
                                PreviewView(document: document,
                                            isActive: document.id == store.activeID && document.isPreviewMode)
                                    .opacity(document.isPreviewMode ? 1 : 0)
                                    .allowsHitTesting(document.isPreviewMode)
                                    .accessibilityHidden(!document.isPreviewMode)
                                Group {
                                    if document.isSourceMode {
                                        EditorView(document: document,
                                                   isActive: document.id == store.activeID && !document.isPreviewMode)
                                    } else {
                                        RichEditorView(document: document,
                                                       isActive: document.id == store.activeID && !document.isPreviewMode)
                                    }
                                }
                                .opacity(document.isPreviewMode ? 0 : 1)
                                .allowsHitTesting(!document.isPreviewMode)
                                .accessibilityHidden(document.isPreviewMode)
                            }
                        }
                    }
                    .animation(reduceMotion ? nil : AppTheme.transitionAnimation, value: document.isPreviewMode)
                    .opacity(document.id == store.activeID ? 1 : 0)
                    .allowsHitTesting(document.id == store.activeID)
                    .disabled(document.id != store.activeID)
                    .accessibilityHidden(document.id != store.activeID)
                }
            }
        } else {
            if store.folderRoot == nil && !store.recentFiles.isEmpty {
                recentFiles
            } else {
                placeholder
            }
        }
    }

    private var recentFiles: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("最近打开")
                    .font(.title2.weight(.semibold))
                VStack(spacing: 6) {
                    ForEach(store.recentFiles) { file in
                        HStack(spacing: 8) {
                            Button { store.handleOpen(file.url) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.secondary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(file.url.lastPathComponent)
                                            .font(.callout.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Text(file.url.deletingLastPathComponent().path)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                    Spacer(minLength: 8)
                                    Text(file.lastOpened.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("打开 \(file.url.lastPathComponent)")
                            Button { store.removeRecentFile(file.url) } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("从最近记录移除，不删除文件")
                            .accessibilityLabel("从最近记录移除 \(file.url.lastPathComponent)")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .frame(maxWidth: 640)
            .padding(28)
            .frame(maxWidth: .infinity)
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
