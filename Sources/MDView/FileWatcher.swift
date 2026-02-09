import Foundation

final class FileWatcher {
    private let url: URL
    private let callback: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    init(url: URL, callback: @escaping () -> Void) {
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
            guard let self = self else { return }
            let flags = source.data

            self.callback()

            if flags.contains(.delete) || flags.contains(.rename) || flags.contains(.revoke) {
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + .milliseconds(150)) {
                    self.start()
                }
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
        stop()
    }
}
