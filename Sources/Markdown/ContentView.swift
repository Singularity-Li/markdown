import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    let store: DocumentStore

    var body: some View {
        VStack(spacing: 0) {
            WindowToolbarView(store: store)
            Divider().opacity(0.2)
            // 分栏仅作用于下方内容，不延伸到公共工具栏和标签栏。
            HSplitView {
                if store.folderRoot != nil && store.showsSidebar {
                    SidebarView(store: store)
                        .frame(minWidth: 190, idealWidth: 240, maxWidth: 360)
                }
                DetailView(store: store)
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.top, 2)
        .background(Color.clear)
        .onDrop(of: [UTType.fileURL], isTargeted: Binding(
            get: { store.isDropTargeted }, set: { store.isDropTargeted = $0 }
        )) { providers in
            guard !providers.isEmpty else { return false }
            loadDroppedURLs(providers)
            return true
        }
        .overlay {
            if store.isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
        .alert("无法完成操作", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("好") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
    // 顺序读取全部拖入项，保持标签顺序，不因异步回调遗漏文件。
    private func loadDroppedURLs(_ providers: [NSItemProvider], index: Int = 0, urls: [URL] = []) {
        guard index < providers.count else { store.handleOpen(urls); return }
        _ = providers[index].loadObject(ofClass: URL.self) { url, _ in
            DispatchQueue.main.async {
                loadDroppedURLs(providers, index: index + 1, urls: urls + (url.map { [$0] } ?? []))
            }
        }
    }

}
