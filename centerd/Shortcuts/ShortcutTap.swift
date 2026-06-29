import Cocoa
import CoreGraphics

/// A resolved binding: a parsed shortcut plus the application it should target.
nonisolated public struct ShortcutBinding {

    /// The display name of the bound application (e.g. `"Google Chrome"`).
    let displayName: String

    /// The `CFBundleIdentifier` of the bound application.
    let bundleId: String

    /// The shortcut that triggers this binding.
    let shortcut: ParsedShortcut

}

/// Receives shortcut events from the tap. All callbacks arrive on the main actor.
@MainActor
public protocol ShortcutTapDelegate: AnyObject {

    /// A configured shortcut's full chord (modifiers + main key) was pressed.
    /// Fires on every matching key-down while the modifiers are held.
    func shortcutTriggered(_ binding: ShortcutBinding)

    /// The modifiers of the most recently triggered shortcut were released.
    func modifiersReleased()

}

public protocol ShortcutTap {

    /// Installs the event tap. Returns `false` if the process is not trusted or tap creation fails.
    func start() -> Bool

    /// Removes the event tap.
    func stop()

    /// Replaces the set of active shortcut bindings.
    func update(shortcuts: [ParsedShortcut: ShortcutBinding])

}

public final class SystemShortcutTap: ShortcutTap {

    private weak var delegate: ShortcutTapDelegate?

    // These are only ever read/written on the main thread: the tap's run-loop source is
    // installed on the main run loop, so its callback fires on the main thread.
    nonisolated(unsafe) private var shortcuts: [ParsedShortcut: ShortcutBinding] = [:]
    nonisolated(unsafe) private var engagedModifiers: CGEventFlags = []
    nonisolated(unsafe) private var eventTap: CFMachPort?
    nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?

    init(delegate: ShortcutTapDelegate) {
        self.delegate = delegate
    }

    public func update(shortcuts: [ParsedShortcut: ShortcutBinding]) {
        self.shortcuts = shortcuts
    }

    public func start() -> Bool {
        guard eventTap == nil else { return true }

        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(mask),
                callback: shortcutTapCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        else {
            NSLog("centerd: failed to create event tap (missing Accessibility/Input Monitoring permission?)")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source
        return true
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        engagedModifiers = []
    }

    /// Synchronously handles a tapped event. Runs on the main thread (main run loop).
    /// Returns `nil` to swallow the event, or the event itself to pass it through.
    nonisolated fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // The system disables the tap on timeout or heavy input; re-enable and pass through.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            // Never swallow modifier changes. Detect release of the engaged chord.
            if !engagedModifiers.isEmpty,
                !event.flags.intersection(ParsedShortcut.significantMask).isSuperset(of: engagedModifiers)
            {
                engagedModifiers = []
                MainActor.assumeIsolated { delegate?.modifiersReleased() }
            }
            return Unmanaged.passUnretained(event)
        }

        // keyDown: match against configured shortcuts using the layout-independent character.
        guard let character = NSEvent(cgEvent: event)?.charactersIgnoringModifiers?.lowercased().first,
            let binding = matchingBinding(character: character, flags: event.flags)
        else {
            return Unmanaged.passUnretained(event)
        }

        engagedModifiers = binding.shortcut.modifiers
        MainActor.assumeIsolated { delegate?.shortcutTriggered(binding) }
        return nil  // swallow: the focused app must not also receive this key
    }

    nonisolated private func matchingBinding(character: Character, flags: CGEventFlags) -> ShortcutBinding? {
        for (shortcut, binding) in shortcuts where shortcut.key == character && shortcut.matches(flags: flags) {
            return binding
        }
        return nil
    }

}

/// Top-level C callback for the event tap. Must be `nonisolated` (a C function pointer cannot
/// carry actor isolation) and recovers the tap instance via the `Unmanaged` refcon pattern.
nonisolated private func shortcutTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<SystemShortcutTap>.fromOpaque(refcon).takeUnretainedValue()
    return tap.handle(type: type, event: event)
}
