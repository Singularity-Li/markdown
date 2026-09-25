import SwiftUI

struct DocumentTabsView: View {
    let store: DocumentStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(store.documents) { document in
                        DocumentTab(document: document, store: store)
                            .id(document.id)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .onChange(of: store.activeID) { _, id in
                if let id { proxy.scrollTo(id) }
            }
        }
    }
}

// 显式引用属性包装器，兼容未附带 SwiftUIMacros 插件的命令行 SDK。
private typealias TabState<Value> = SwiftUI.State<Value>

private struct DocumentTab: View {
    let document: OpenDocument
    let store: DocumentStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @TabState private var isHovered = false
    @TabState private var isCloseHovered = false

    private var isSelected: Bool { document.id == store.activeID }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 8, style: .continuous) }
    private var surface: Color {
        if isSelected {
            return Color(nsColor: .controlBackgroundColor)
                .opacity(reduceTransparency ? 1 : (colorScheme == .dark ? 0.85 : 0.78))
        }
        return Color.primary.opacity(isHovered ? 0.065 : 0.025)
    }

    private var titleColor: Color { isSelected ? .primary : .secondary }
    private var iconColor: Color { isSelected ? .accentColor : .secondary }

    private var tabLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: document.isDirty ? "circle.fill" : "doc.text")
                .font(.system(size: document.isDirty ? 6 : 11, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 12)
            Text(document.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.leading, 11)
        .frame(height: 28)
        .contentShape(Rectangle())
    }

    var body: some View {
        HStack(spacing: 4) {
            Button {
                store.activate(document.id)
            } label: {
                tabLabel
            }
            .buttonStyle(.plain)
            .accessibilityLabel(document.displayName + (document.isDirty ? "，未保存" : ""))
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Button { store.close(document.id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isCloseHovered ? Color.primary : Color.secondary)
                    .frame(width: 18, height: 18)
                    .background(Color.primary.opacity(isCloseHovered ? 0.09 : 0),
                                in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .frame(width: 26, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isCloseHovered = $0 }
            .accessibilityLabel("关闭标签：" + document.displayName)
            .help("关闭标签页")
        }
        .frame(maxWidth: 240)
        .frame(height: 28)
        .background(surface, in: shape)
        .overlay {
            shape.strokeBorder(Color.primary.opacity(isSelected ? (contrast == .increased ? 0.45 : 0.12) : 0),
                               lineWidth: contrast == .increased ? 1 : 0.5)
        }
        .overlay(alignment: .bottom) {
            // 小面积强调色与浮起的底色共同标识当前标签，不依赖整块蓝色填充。
            Capsule()
                .fill(Color.accentColor)
                .frame(width: 18, height: 2)
                .padding(.bottom, 1)
                .opacity(isSelected ? 1 : 0)
                .accessibilityHidden(true)
        }
        .shadow(color: Color.black.opacity(isSelected ? (colorScheme == .dark ? 0.20 : 0.07) : 0),
                radius: 2, x: 0, y: 1)
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isSelected)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isHovered)
        .help(document.url?.path ?? document.displayName)
    }
}
