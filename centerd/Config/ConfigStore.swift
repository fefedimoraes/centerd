import Foundation

public protocol ConfigStore {

    /// The most recently loaded configuration, or `Config.default` if none has loaded successfully.
    var current: Config { get }

    /// Invoked on the main queue whenever a reload produces a new configuration.
    var onChange: ((Config) -> Void)? { get set }

    /// Synchronously reads and decodes the config file, updating `current` on success.
    /// On failure the previous `current` is kept (the agent never crashes on bad config).
    func reload()

    /// Begins watching the config file's parent directory for changes.
    /// No-op when the current configuration disables `hot-reload-config`.
    func startWatching()

    /// Stops watching the config file's parent directory.
    func stopWatching()

}

public final class FileConfigStore: ConfigStore {

    private let fileURL: URL
    private let directoryURL: URL

    private var config: Config = .default
    private var source: DispatchSourceFileSystemObject?
    private var directoryDescriptor: CInt = -1
    private var debounceWorkItem: DispatchWorkItem?

    public var current: Config { config }
    public var onChange: ((Config) -> Void)?

    init() {
        let configDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("centerd", isDirectory: true)
        self.directoryURL = configDirectory
        self.fileURL = configDirectory.appendingPathComponent("config.json", isDirectory: false)
    }

    public func reload() {
        guard let data = try? Data(contentsOf: fileURL) else {
            NSLog("centerd: no config file at \(fileURL.path); keeping current config")
            return
        }

        do {
            let decoded = try JSONDecoder().decode(Config.self, from: data)
            let changed = decoded != config
            config = decoded
            if changed {
                onChange?(decoded)
            }
        } catch {
            NSLog("centerd: failed to decode config: \(error); keeping current config")
        }
    }

    public func startWatching() {
        guard config.options.hotReloadConfig else { return }
        guard source == nil else { return }

        // Watch the parent directory rather than the file: editors typically save via
        // atomic rename-replace, which invalidates a file-level descriptor.
        let descriptor = open(directoryURL.path, O_EVTONLY)
        guard descriptor >= 0 else {
            NSLog("centerd: unable to watch config directory at \(directoryURL.path)")
            return
        }

        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        newSource.setEventHandler { [weak self] in
            self?.scheduleReload()
        }
        newSource.setCancelHandler {
            close(descriptor)
        }
        newSource.resume()

        self.directoryDescriptor = descriptor
        self.source = newSource
    }

    public func stopWatching() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        source?.cancel()
        source = nil
        directoryDescriptor = -1
    }

    /// Debounces rapid filesystem events (e.g. multi-write saves) before reloading.
    private func scheduleReload() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.reload()
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

}
