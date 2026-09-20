import SwiftUI

/// 全窗口共用一行工具栏，侧栏与正文没有各自不同高度的标题区。
struct WindowToolbarView: View {
    let store: DocumentStore
    private let appearance = AppearanceSettings.shared

    var body: some View {
        HStack(spacing: 10) {
            if let folder = store.folderRoot {
                Button { store.showsSidebar.toggle() } label: {
                    Image(systemName: "sidebar.left")
                }
                .buttonStyle(.glass)
                .help(store.showsSidebar ? "收起侧栏" : "展开侧栏")
                .accessibilityLabel(store.showsSidebar ? "收起侧栏" : "展开侧栏")

                if store.showsSidebar {
                    Label(folder.lastPathComponent, systemImage: "folder")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(folder.path)
                    if store.hasLoadedDocument {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if store.hasLoadedDocument || !store.showsSidebar {
                Label(store.displayTitle + (store.isDirty ? " · 未保存" : ""), systemImage: "doc.text")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 12)
            Button { store.showsAppearancePopover.toggle() } label: {
                Image(systemName: "circle.lefthalf.filled")
            }
            .buttonStyle(.glass)
            .help("调整 Liquid Glass 透明度")
            .accessibilityLabel("玻璃透明度")
            .popover(isPresented: Binding(
                get: { store.showsAppearancePopover },
                set: { store.showsAppearancePopover = $0 }
            ), arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("玻璃透明度").font(.headline)
                        Spacer()
                        Text("\(Int((appearance.transparency * 100).rounded()))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { appearance.transparency },
                        set: { appearance.transparency = $0 }
                    ), in: 0...1, step: 0.01)
                    .accessibilityLabel("窗口背景透明度")
                    .accessibilityValue("\(Int((appearance.transparency * 100).rounded()))%")
                    HStack {
                        Text("更实")
                        Spacer()
                        Text("更透")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text("自动保存，下次打开继续使用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(width: 260)
            }

            Button { OpenPanelHelper.openPanel() } label: {
                Label("打开", systemImage: "folder")
            }
            .buttonStyle(.glass)
            .help("打开 Markdown 文件或文件夹 (⌘O)")
            .accessibilityLabel("打开文件或文件夹")

            Toggle(isOn: Binding(
                get: { store.isPreviewMode }, set: { store.isPreviewMode = $0 }
            )) {
                Text(store.isPreviewMode ? "预览" : "编辑")
                    .fontWeight(.medium)
                    .foregroundStyle(store.isPreviewMode ? Color.blue : Color.orange)
            }
            .toggleStyle(.switch)
            .controlSize(.large)
            .disabled(store.activeDocument?.isSupported != true)
            .tint(.blue)
            .help(store.isPreviewMode ? "切换到编辑模式" : "切换到预览模式")
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
    }
}
