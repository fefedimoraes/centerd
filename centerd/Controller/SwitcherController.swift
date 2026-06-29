import Cocoa
import CoreGraphics
import SwiftUI

/// Orchestrates the switching interaction: resolves the target app, branches between the
/// fast path (one window) and the switcher popup (many windows), cycles the selection while
/// the chord is held, and commits on release. All state lives on the main actor.
@MainActor
public final class SwitcherController: ShortcutTapDelegate {

    private enum State {
        case idle
        case switching(Session)
    }

    private struct Session {
        let binding: ShortcutBinding
        let app: Application
        var windows: [Window]
        var selection: Int
    }

    private let workspace: Workspace
    private let windowFinder: WindowFinder
    private let configStore: ConfigStore

    private let viewModel = SwitcherViewModel()
    private lazy var panel = SwitcherPanel(model: viewModel)

    private var state: State = .idle

    init(workspace: Workspace, windowFinder: WindowFinder, configStore: ConfigStore) {
        self.workspace = workspace
        self.windowFinder = windowFinder
        self.configStore = configStore
    }

    // MARK: - ShortcutTapDelegate

    public func shortcutTriggered(_ binding: ShortcutBinding) {
        switch state {
        case .idle:
            beginSession(binding)
        case .switching:
            cycleSelection()
        }
    }

    public func modifiersReleased() {
        guard case .switching(let session) = state else { return }
        panel.dismiss()
        commit(window: session.windows[session.selection], app: session.app)
        state = .idle
    }

    // MARK: - Trigger

    private func beginSession(_ binding: ShortcutBinding) {
        guard let app = resolveApp(binding) else {
            return  // not running, launched (or launchable), or fully absent — nothing to switch to now
        }

        let windows = windowFinder.getLiveWindows(app.processIdentifier)
        switch windows.count {
        case 0:
            _ = app.activate()
        case 1:
            _ = app.activate()
            commit(window: windows[0], app: app)
        default:
            // Mirror Cmd+Tab: if the app is already frontmost, default to the second window.
            let selection = app.isActive ? 1 : 0
            presentSwitcher(binding: binding, app: app, windows: windows, selection: selection)
        }
    }

    /// Resolves the application to act on, launching it if configured and not currently running.
    private func resolveApp(_ binding: ShortcutBinding) -> Application? {
        if let running = workspace.getRunningApplications(withBundleIdentifier: binding.bundleId).first {
            return running
        }

        // Not running. Launch it (launch only — the user re-triggers once it is open).
        if configStore.current.options.launchApplication,
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: binding.bundleId)
        {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
        return nil
    }

    // MARK: - Switcher popup

    private func presentSwitcher(binding: ShortcutBinding, app: Application, windows: [Window], selection: Int) {
        viewModel.appName = app.localizedName ?? binding.displayName
        viewModel.appIcon = app.icon
        viewModel.items = windows.map { SwitcherItem(id: $0.id, title: $0.title ?? "") }
        viewModel.selection = selection
        panel.present()
        state = .switching(Session(binding: binding, app: app, windows: windows, selection: selection))
    }

    private func cycleSelection() {
        guard case .switching(var session) = state else { return }
        session.selection = (session.selection + 1) % session.windows.count
        viewModel.selection = session.selection
        state = .switching(session)
    }

    // MARK: - Commit

    /// Brings the chosen window to the front and (if enabled) centers the mouse on it.
    private func commit(window: Window, app: Application) {
        _ = app.activate()
        AXUIElementSetAttributeValue(window.element, kAXMainAttribute as CFString, kCFBooleanTrue)
        window.raise()

        guard configStore.current.options.centerMouseCursor, let frame = window.frame() else { return }
        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
        // CGWarpMouseCursorPosition transiently disassociates the cursor from the mouse; re-associate
        // immediately so the next physical movement does not jump.
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
    }

}
