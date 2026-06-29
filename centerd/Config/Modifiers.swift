import Cocoa
import CoreGraphics

/// A shortcut parsed into a set of modifier flags plus a single main key.
///
/// The main key is matched against the *typed character* the keyboard event produces
/// for the current layout (rather than a fixed physical keycode), so bindings behave
/// correctly across non-US layouts.
nonisolated public struct ParsedShortcut: Hashable {

    /// The modifier keys that must be held, as `CGEventFlags`, for matching tap events.
    let modifiers: CGEventFlags

    /// The lowercased main key character (e.g. `"b"`).
    let key: Character

    /// The same modifiers expressed as `NSEvent.ModifierFlags`, for display/debugging.
    let displayModifiers: NSEvent.ModifierFlags

    public static func == (lhs: ParsedShortcut, rhs: ParsedShortcut) -> Bool {
        return lhs.modifiers == rhs.modifiers && lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(modifiers.rawValue)
        hasher.combine(key)
    }

}

nonisolated extension ParsedShortcut {

    /// The subset of `CGEventFlags` we consider significant when matching events.
    /// Other bits (caps lock, numeric pad, device-dependent flags) are ignored.
    static let significantMask: CGEventFlags = [.maskControl, .maskShift, .maskCommand, .maskAlternate]

    /// Parses shortcut tokens such as `["control", "shift", "b"]` into a `ParsedShortcut`.
    ///
    /// All but the last token are treated as modifiers; the last token is the main key.
    /// Returns `nil` if there is no main key, an unknown modifier token, or the main key
    /// is not a single character.
    init?(tokens: [String]) {
        guard let rawKey = tokens.last, tokens.count >= 1 else { return nil }

        var cgFlags: CGEventFlags = []
        var nsFlags: NSEvent.ModifierFlags = []
        for token in tokens.dropLast() {
            switch token.lowercased() {
            case "control", "ctrl":
                cgFlags.insert(.maskControl)
                nsFlags.insert(.control)
            case "shift":
                cgFlags.insert(.maskShift)
                nsFlags.insert(.shift)
            case "command", "cmd":
                cgFlags.insert(.maskCommand)
                nsFlags.insert(.command)
            case "option", "opt", "alt":
                cgFlags.insert(.maskAlternate)
                nsFlags.insert(.option)
            default:
                return nil
            }
        }

        let normalizedKey = rawKey.lowercased()
        guard normalizedKey.count == 1, let key = normalizedKey.first else { return nil }

        self.modifiers = cgFlags
        self.key = key
        self.displayModifiers = nsFlags
    }

    /// Returns `true` if the given event flags match this shortcut's modifiers exactly,
    /// ignoring flags outside `significantMask`.
    func matches(flags: CGEventFlags) -> Bool {
        return flags.intersection(Self.significantMask) == modifiers
    }

}
