import Foundation

/// The user-configurable options controlling `centerd`'s behavior.
public struct Options: Codable, Equatable {

    /// When `true`, the mouse cursor is centered in the destination window after switching.
    let centerMouseCursor: Bool

    /// When `true`, a bound application that is not running is launched on trigger.
    let launchApplication: Bool

    /// When `true`, the configuration file is watched and reloaded automatically on change.
    let hotReloadConfig: Bool

    enum CodingKeys: String, CodingKey {
        case centerMouseCursor = "center-mouse-cursor"
        case launchApplication = "launch-application"
        case hotReloadConfig = "hot-reload-config"
    }

}

/// The configuration for a single bound application.
public struct ApplicationConfig: Codable, Equatable {

    /// The `CFBundleIdentifier` of the application to target (e.g. `com.google.Chrome`).
    let bundleId: String

    /// The shortcut tokens, e.g. `["control", "shift", "b"]`.
    /// All but the last token are modifiers; the last token is the main key.
    let shortcut: [String]

    enum CodingKeys: String, CodingKey {
        case bundleId = "bundle-id"
        case shortcut
    }

}

/// The root configuration model, decoded from `~/.config/centerd/config.json`.
public struct Config: Codable, Equatable {

    let options: Options

    /// Bound applications, keyed by their display name (e.g. `"Google Chrome"`).
    let applications: [String: ApplicationConfig]

    /// A safe default used before a config is loaded, or when loading fails.
    static let `default` = Config(
        options: Options(centerMouseCursor: true, launchApplication: true, hotReloadConfig: true),
        applications: [:]
    )

}
