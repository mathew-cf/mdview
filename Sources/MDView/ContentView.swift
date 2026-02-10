import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if appState.fileURL != nil {
                    MarkdownWebView(
                        markdown: appState.markdownContent,
                        baseURL: appState.fileURL?.deletingLastPathComponent(),
                        zoomLevel: appState.zoomLevel
                    )
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appState.isQuickOpenVisible {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.12)) {
                            appState.isQuickOpenVisible = false
                        }
                    }

                QuickOpenView(
                    isPresented: $appState.isQuickOpenVisible,
                    files: appState.markdownFiles,
                    directoryURL: appState.directoryURL,
                    onSelect: { appState.loadFile($0, changeDirectory: false) }
                )
                .padding(.top, 40)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .navigationTitle(appState.fileName)
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Open a Markdown File")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("⌘O to open  ·  or drag a file or folder here")
                .font(.callout)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
            guard
                let urlData = data as? Data,
                let url = URL(dataRepresentation: urlData, relativeTo: nil)
            else { return }

            Task { @MainActor in
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

                if isDir.boolValue {
                    appState.loadDirectory(url)
                } else {
                    let ext = url.pathExtension.lowercased()
                    guard ["md", "markdown", "mdown", "mkd", "mkdn", "txt"].contains(ext) else { return }
                    appState.loadFile(url)
                }
            }
        }
        return true
    }
}
