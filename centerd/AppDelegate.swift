import Cocoa
import SwiftUI

/// Owns every service and the agent lifecycle: installs the status-bar item, wires the
/// config store to the shortcut tap, requests Accessibility permission, and starts the tap.
///
/// Explicitly `@MainActor` so the app builds on toolchains that do not default to main-actor
/// isolation (e.g. older Xcode on CI), where the lazy services below would otherwise be
/// nonisolated and unable to construct the main-actor-isolated `SwitcherController`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let workspace: Workspace = SystemWorkspace()
    private let accessibility: Accessibility = SystemAccessibility()
    private lazy var windowFinder: WindowFinder = SystemWindowFinder(accessibility: accessibility)
    private var configStore: ConfigStore = FileConfigStore()
    private lazy var controller = SwitcherController(
        workspace: workspace, windowFinder: windowFinder, configStore: configStore)
    private lazy var tap: ShortcutTap = SystemShortcutTap(delegate: controller)

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()

        if !accessibility.isProcessTrusted() {
            accessibility.promptForAccessbility()
        }

        configStore.onChange = { [weak self] config in self?.applyConfig(config) }
        configStore.reload()
        applyConfig(configStore.current)
        configStore.startWatching()

        _ = tap.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        tap.stop()
        configStore.stopWatching()
    }

    /// Translates the current config into parsed shortcut bindings and hands them to the tap.
    private func applyConfig(_ config: Config) {
        var shortcuts = [ParsedShortcut: ShortcutBinding]()
        for (displayName, appConfig) in config.applications {
            guard let shortcut = ParsedShortcut(tokens: appConfig.shortcut) else {
                NSLog("centerd: invalid shortcut for \(displayName): \(appConfig.shortcut)")
                continue
            }
            shortcuts[shortcut] = ShortcutBinding(
                displayName: displayName,
                bundleId: appConfig.bundleId,
                shortcut: shortcut
            )
        }
        tap.update(shortcuts: shortcuts)
    }

    // MARK: - Status item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.center.inset.filled", accessibilityDescription: "centerd")

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit centerd", action: #selector(quit), keyEquivalent: "q"))
        for menuItem in menu.items where menuItem.action != nil {
            menuItem.target = self
        }
        item.menu = menu
        statusItem = item
    }

    @objc private func reloadConfig() {
        configStore.reload()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

}
