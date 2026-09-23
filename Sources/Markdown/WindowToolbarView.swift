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
                .buttonStyle(CompactToolbarButtonStyle())
                .help(store.showsSidebar ? "收起侧栏" : "展开侧栏")
                .accessibilityLabel(store.showsSidebar ? "收起侧栏" : "展开侧栏")

                if store.showsSidebar {
                    Label(folder.lastPathComponent, systemImage: "folder")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(folder.path)
                }
            }

            if !store.documents.isEmpty {
                DocumentTabsView(store: store)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer(minLength: 12)
            }
            Button { store.newDocument() } label: {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(CompactToolbarButtonStyle())
            .help("新建文件 (⌘N)")
            .accessibilityLabel("新建文件")

            Button { OpenPanelHelper.openPanel() } label: {
                Image(systemName: "folder")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(CompactToolbarButtonStyle())
            .help("打开 Markdown 文件或文件夹 (⌘O)")
            .accessibilityLabel("打开文件或文件夹")

            Button { store.showsAppearancePopover.toggle() } label: {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(CompactToolbarButtonStyle())
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
                    ), in: 0...1)
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

            HStack(spacing: 0) {
                modeButton("编辑", preview: false, color: .orange)
                modeButton("预览", preview: true, color: .blue)
            }
            .frame(height: 28)
            .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .disabled(store.activeDocument?.isSupported != true)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("阅读模式")
        }
        .padding(.horizontal, 14)
        .padding(.leading, 74)
        .frame(height: 36)
    }

    private func modeButton(_ title: String, preview: Bool, color: Color) -> some View {
        Button { store.isPreviewMode = preview } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(store.isPreviewMode == preview ? color : .secondary)
                .frame(width: 44, height: 28)
                .background(store.isPreviewMode == preview ? color.opacity(0.15) : .clear,
                            in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(store.isPreviewMode == preview ? .isSelected : [])
        .help(preview ? "切换到预览模式" : "切换到编辑模式")
    }
}

private struct CompactToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 34, height: 28)
            .contentShape(Rectangle())
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
