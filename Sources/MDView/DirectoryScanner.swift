import Foundation

enum DirectoryScanner {
    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]

    private static let skipNames: Set<String> = [
        "node_modules", ".build", "Pods", "DerivedData",
        ".svn", ".hg", "vendor", "dist", "build"
    ]

    static func scan(_ directory: URL) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var results: [URL] = []

        for case let url as URL in enumerator {
            let name = url.lastPathComponent

            if let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
               values.isDirectory == true {
                if skipNames.contains(name) {
                    enumerator.skipDescendants()
                }
                continue
            }

            if markdownExtensions.contains(url.pathExtension.lowercased()) {
                results.append(url)
            }
        }

        return results.sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    static func relativePath(for file: URL, from directory: URL?) -> String {
        guard let directory = directory else { return file.lastPathComponent }
        let filePath = file.path
        let dirPath = directory.path.hasSuffix("/") ? directory.path : directory.path + "/"
        if filePath.hasPrefix(dirPath) {
            return String(filePath.dropFirst(dirPath.count))
        }
        return file.lastPathComponent
    }
}
