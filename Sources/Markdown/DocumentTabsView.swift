import SwiftUI

struct DocumentTabsView: View {
    let store: DocumentStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(store.documents) { document in
                        HStack(spacing: 5) {
                            Button {
                                store.activate(document.id)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: document.isDirty ? "circle.fill" : "doc.text")
                                        .font(.system(size: document.isDirty ? 7 : 11))
                                    Text(document.displayName)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .padding(.leading, 10)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(document.displayName + (document.isDirty ? "，未保存" : ""))
                            .accessibilityAddTraits(document.id == store.activeID ? .isSelected : [])

                            Button { store.close(document.id) } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .frame(width: 24, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("关闭标签：" + document.displayName)
                            .help("关闭标签页")
                        }
                        .frame(maxWidth: 240)
                        .background(document.id == store.activeID ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(document.id == store.activeID ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                        }
                        .help(document.url?.path ?? document.displayName)
                        .id(document.id)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 3)
            }
            .onChange(of: store.activeID) { _, id in
                if let id { proxy.scrollTo(id) }
            }
        }
    }
}
