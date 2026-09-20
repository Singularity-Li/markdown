import SwiftUI

struct SidebarView: View {
    let store: DocumentStore

    var body: some View {
        VStack(spacing: 0) {
            if let root = store.folderTree, let children = root.children, !children.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(children) { child in
                            SidebarRow(node: child, store: store)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                }
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(store.folderRoot == nil ? "打开文件夹后\n在此浏览整个目录" : "此文件夹为空")
                        .multilineTextAlignment(.center)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }

    }
}

/// 递归目录/文件行。
struct SidebarRow: View {
    let node: FileNode
    let store: DocumentStore

    var body: some View {
        if node.isDirectory {
            if let children = node.children, !children.isEmpty {
                DisclosureGroup(isExpanded: expandedBinding) {
                    ForEach(children) { child in
                        SidebarRow(node: child, store: store)
                    }
                } label: {
                    rowLabel
                }
            } else {
                rowLabel // 空目录
            }
        } else {
            Button {
                store.select(node)
            } label: {
                rowLabel
            }
            .buttonStyle(.plain)
        }
    }

    private var expandedBinding: Binding<Bool> {
        Binding(get: { node.isExpanded }, set: { node.isExpanded = $0 })
    }

    private var rowLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: node.isDirectory ? "folder" : node.icon)
                .foregroundStyle(node.isDirectory ? Color.accentColor : Color.secondary)
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 5)
        .background(store.selectedURL == node.url.standardizedFileURL.resolvingSymlinksInPath() ? Color.accentColor.opacity(0.22) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }
}