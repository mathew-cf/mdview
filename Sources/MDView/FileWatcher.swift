import Foundation

actor FileWatcher {
    private let url: URL
    private let callback: @Sendable () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    init(url: URL, callback: @escaping @Sendable () -> Void) {
        self.url = url
        self.callback = callback
    }

    func start() {
        stop()

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .revoke],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            let rawFlags = source.data.rawValue
            Task { [weak self] in
                await self?.handleEvent(rawFlags: rawFlags)
            }
        }

        source.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }

        self.source = source
        source.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }

    deinit {
        source?.cancel()
    }

    private func handleEvent(rawFlags: UInt) {
        callback()

        let flags = DispatchSource.FileSystemEvent(rawValue: rawFlags)
        if flags.contains(.delete) || flags.contains(.rename) || flags.contains(.revoke) {
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(150))
                await self?.start()
            }
        }
    }
}
