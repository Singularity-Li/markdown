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
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: AppTheme.toolbarCornerRadius, style: .continuous) }
    private var surface: Color {
        if isSelected {
            return Color(nsColor: .controlBackgroundColor)
                .opacity(reduceTransparency ? 1 : (colorScheme == .dark ? 0.85 : 0.78))
        }
        return Color.primary.opacity(isHovered ? 0.065 : 0.025)
    }

    private var titleColor: Color { isSelected ? .primary : .secondary }
    // 与 App 图标中字母 D 使用相同的 sRGB 酒红色（#A63D50）。
    private var selectionColor: Color { AppTheme.accent }

    private let indicatorWidth: CGFloat = 10
    private let indicatorPadding: CGFloat = 4
    private var starGlow: Color {
        Color(nsColor: AppTheme.secondaryAccentNSColor.blended(withFraction: 0.65, of: .white)
              ?? AppTheme.secondaryAccentNSColor)
    }

    private var tabLabel: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(selectionColor)
                .frame(width: 4, height: 4)
                .shadow(color: selectionColor.opacity(0.6), radius: 3)
                .frame(width: indicatorWidth, height: AppTheme.toolbarControlHeight)
                .padding(.horizontal, indicatorPadding)
                .opacity(isSelected ? 1 : 0)
                .accessibilityHidden(true)

            Text(document.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .truncationMode(.middle)
            if document.isDirty {
                Image(systemName: "asterisk")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryAccent)
                    .shadow(color: starGlow.opacity(colorScheme == .dark ? 0.95 : 0.35), radius: 1)
                    .shadow(color: starGlow.opacity(colorScheme == .dark ? 0.65 : 0.2), radius: 3)
                    .frame(width: indicatorWidth, height: AppTheme.toolbarControlHeight, alignment: .center)
                    .padding(.horizontal, indicatorPadding)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: AppTheme.toolbarControlHeight)
        .contentShape(Rectangle())
    }

    var body: some View {
        HStack(spacing: 0) {
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
                    .frame(width: 26, height: AppTheme.toolbarControlHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isCloseHovered = $0 }
            .accessibilityLabel("关闭标签：" + document.displayName)
            .help("关闭标签页")
        }
        .frame(maxWidth: 240)
        .frame(height: AppTheme.toolbarControlHeight)
        .background(surface, in: shape)
        .overlay {
            shape.strokeBorder(Color.primary.opacity(isSelected ? (contrast == .increased ? 0.45 : 0.12) : 0),
                               lineWidth: contrast == .increased ? 1 : 0.5)
        }
        .shadow(color: Color.black.opacity(isSelected ? (colorScheme == .dark ? 0.20 : 0.07) : 0),
                radius: 2, x: 0, y: 1)
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isSelected)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isHovered)
        .help(document.url?.path ?? document.displayName)
    }
}
