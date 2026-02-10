import SwiftUI
import UniformTypeIdentifiers

@MainActor
class AppState: ObservableObject {
    @Published var fileURL: URL?
    @Published var markdownContent: String = ""
    @Published var fileName: String = "MDView"
    @Published var directoryURL: URL?
    @Published var markdownFiles: [URL] = []
    @Published var isQuickOpenVisible = false

    private var fileWatcher: FileWatcher?

    func openFileOrDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.message = "Select a Markdown file or a directory"

        var types: [UTType] = []
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        if let markdown = UTType(filenameExtension: "markdown") { types.append(markdown) }
        types.append(.plainText)
        panel.allowedContentTypes = types

        guard panel.runModal() == .OK, let url = panel.url else { return }

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

        if isDir.boolValue {
            loadDirectory(url)
        } else {
            loadFile(url)
        }
    }

    func loadFile(_ url: URL, changeDirectory: Bool = true) {
        fileURL = url
        fileName = url.lastPathComponent
        readFile()
        startWatching()

        if changeDirectory {
            let parentDir = url.deletingLastPathComponent()
            if directoryURL?.path != parentDir.path {
                directoryURL = parentDir
                markdownFiles = DirectoryScanner.scan(parentDir)
            }
        }
    }

    func loadDirectory(_ url: URL) {
        directoryURL = url
        markdownFiles = DirectoryScanner.scan(url)
        fileWatcher?.stop()
        fileWatcher = nil
        fileURL = nil
        markdownContent = ""
        fileName = url.lastPathComponent
        showQuickOpen()
    }

    func showQuickOpen() {
        if let dir = directoryURL {
            markdownFiles = DirectoryScanner.scan(dir)
        }
        withAnimation(.easeOut(duration: 0.15)) {
            isQuickOpenVisible = true
        }
    }

    func reload() {
        readFile()
    }

    private func readFile() {
        guard let url = fileURL else { return }
        do {
            markdownContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            markdownContent = "> **Error reading file:** \(error.localizedDescription)"
        }
    }

    private func startWatching() {
        fileWatcher?.stop()
        guard let url = fileURL else { return }
        fileWatcher = FileWatcher(url: url) { [weak self] in
            Task { @MainActor [weak self] in
                self?.readFile()
            }
        }
        fileWatcher?.start()
    }
}
