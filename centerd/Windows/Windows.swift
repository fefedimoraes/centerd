import Cocoa
import CoreGraphics

typealias CGWindow = [CFString: Any]

/// tests have shown that this ID has a range going from 0 to probably UInt.MAX
/// it starts at 0 for each app, and increments over time, for each new UI element
/// this means that long-lived apps (e.g. Finder) may have high IDs
/// we don't know how high it can go, and if it wraps around
typealias AXUIElementID = UInt64

public struct Bounds {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

public struct CGWindowAttributes {
    let windowNumber: Int
    let ownerProcessIdentifier: pid_t
    let ownerProcessName: String
    let bounds: Bounds
}

public struct AXAttributes: Hashable {
    let title: String?
    let role: String?
    let subrole: String?
    let windows: [AXAttributes]?
}

enum AxError: Error {
    case permissionError
    case runtimeError
    case invalidElement
}

extension CGWindowAttributes {
    init(_ cgWindow: CGWindow) {
        let bounds = cgWindow[kCGWindowBounds as CFString] as! [String: Any]

        self.windowNumber = cgWindow[kCGWindowNumber as CFString] as! Int
        self.ownerProcessName = cgWindow[kCGWindowOwnerName as CFString] as! String
        self.ownerProcessIdentifier = cgWindow[kCGWindowOwnerPID as CFString] as! pid_t
        self.bounds = Bounds(
            x: bounds["X"] as! Int, y: bounds["Y"] as! Int,
            width: bounds["Width"] as! Int, height: bounds["Height"] as! Int)
    }
}

extension AXAttributes {

    init(_ element: AXUIElement) throws {
        let keys = [
            kAXTitleAttribute,
            kAXRoleAttribute,
            kAXSubroleAttribute,
            kAXWindowsAttribute,
        ]

        var values: CFArray?
        let result = AXUIElementCopyMultipleAttributeValues(element, keys as CFArray, [], &values)
        if result == .cannotComplete {
            throw AxError.runtimeError
        }
        if result == .invalidUIElement {
            throw AxError.invalidElement
        }

        let valuesByKey = Dictionary(uniqueKeysWithValues: zip(keys, values! as [AnyObject]))

        self.title = valuesByKey[kAXTitleAttribute] as? String
        self.role = valuesByKey[kAXRoleAttribute] as? String
        self.subrole = valuesByKey[kAXSubroleAttribute] as? String
        self.windows = try (valuesByKey[kAXWindowsAttribute] as? [AXUIElement])?.map { try AXAttributes($0) }
    }

}

public protocol WindowFinder {

    func getWindows(_ processIdentifier: pid_t) -> [AXAttributes]

    /// Returns live, actionable windows for the given process, de-duplicated by `CGWindowID`
    /// and ordered to approximate z-order (frontmost first).
    func getLiveWindows(_ processIdentifier: pid_t) -> [Window]

}

public class SystemWindowFinder: WindowFinder {

    private let accessibility: Accessibility

    init(accessibility: Accessibility) {
        self.accessibility = accessibility
    }

    public func getWindows(_ processIdentifier: pid_t) -> [AXAttributes] {
        if !accessibility.isProcessTrusted() {
            accessibility.promptForAccessbility()
            return []
        }

        return SystemWindowFinder.getAllWindows(processIdentifier)
    }

    public func getLiveWindows(_ processIdentifier: pid_t) -> [Window] {
        if !accessibility.isProcessTrusted() {
            accessibility.promptForAccessbility()
            return []
        }

        // Try the cheap application-level window list first; only brute-force (which iterates
        // up to 1000 remote tokens and costs tens of milliseconds) when it yields fewer than
        // two windows. The app's kAXWindowsAttribute order approximates z-order (frontmost first).
        let appElement = AXUIElementCreateApplication(processIdentifier)
        var elements = SystemWindowFinder.windowElements(of: appElement)
        if elements.count < 2 {
            elements += SystemWindowFinder.bruteForceWindowElements(processIdentifier)
        }

        var seen = Set<CGWindowID>()
        var windows = [Window]()
        for element in elements {
            guard let window = SystemWindowFinder.makeWindow(element, pid: processIdentifier) else { continue }
            if seen.insert(window.id).inserted {
                windows.append(window)
            }
        }
        return windows
    }

    /// Builds a `Window` from a live element, reading its `CGWindowID` and title.
    private static func makeWindow(_ element: AXUIElement, pid: pid_t) -> Window? {
        var windowId = CGWindowID(0)
        guard _AXUIElementGetWindow(element, &windowId) == .success else { return nil }
        let title = try? AXAttributes(element).title
        return Window(id: windowId, element: element, pid: pid, title: title ?? nil)
    }

    /// The window child elements directly exposed by the application element, if any.
    private static func windowElements(of appElement: AXUIElement) -> [AXUIElement] {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &ref) == .success,
            let elements = ref as? [AXUIElement]
        else {
            return []
        }
        return elements
    }

    private static func getAllWindows(_ processIdentifier: pid_t) -> [AXAttributes] {
        guard let attributes = try? AXAttributes(AXUIElementCreateApplication(processIdentifier)) else {
            return []
        }

        return Array(Set((attributes.windows ?? []) + getWindowsByBruteForce(processIdentifier)))
    }

    /// Brute-force getting the windows of a process by iterating over AXUIElementID one by one
    private static func getWindowsByBruteForce(_ pid: pid_t) -> [AXAttributes] {
        // we use this to call _AXUIElementCreateWithRemoteToken; we reuse the object for performance
        // tests showed that this remoteToken is 20 bytes: 4 + 4 + 4 + 8; the order of bytes matters
        var remoteToken = Data(count: 20)
        remoteToken.replaceSubrange(0..<4, with: withUnsafeBytes(of: pid) { Data($0) })
        remoteToken.replaceSubrange(4..<8, with: withUnsafeBytes(of: Int32(0)) { Data($0) })
        remoteToken.replaceSubrange(8..<12, with: withUnsafeBytes(of: Int32(0x636f_636f)) { Data($0) })

        // We iterate to 1000 as a tradeoff between performance, and missing windows of long-lived processes.
        // Different apps can take widely different time for this to complete.
        var axAttributes = [AXAttributes]()
        for axUiElementId: AXUIElementID in 0..<1000 {
            remoteToken.replaceSubrange(12..<20, with: withUnsafeBytes(of: axUiElementId) { Data($0) })
            if let axUiElement = _AXUIElementCreateWithRemoteToken(remoteToken as CFData)?.takeRetainedValue(),
                let attributes = try? AXAttributes(axUiElement),
                [kAXStandardWindowSubrole, kAXDialogSubrole].contains(attributes.subrole)
            {
                axAttributes.append(attributes)
            }
        }

        return axAttributes
    }

    /// Brute-force discovery returning the live window elements (rather than snapshots), so callers
    /// can act on them. Mirrors `getWindowsByBruteForce` but keeps the `AXUIElement` references.
    private static func bruteForceWindowElements(_ pid: pid_t) -> [AXUIElement] {
        var remoteToken = Data(count: 20)
        remoteToken.replaceSubrange(0..<4, with: withUnsafeBytes(of: pid) { Data($0) })
        remoteToken.replaceSubrange(4..<8, with: withUnsafeBytes(of: Int32(0)) { Data($0) })
        remoteToken.replaceSubrange(8..<12, with: withUnsafeBytes(of: Int32(0x636f_636f)) { Data($0) })

        var elements = [AXUIElement]()
        for axUiElementId: AXUIElementID in 0..<1000 {
            remoteToken.replaceSubrange(12..<20, with: withUnsafeBytes(of: axUiElementId) { Data($0) })
            if let axUiElement = _AXUIElementCreateWithRemoteToken(remoteToken as CFData)?.takeRetainedValue(),
                let attributes = try? AXAttributes(axUiElement),
                [kAXStandardWindowSubrole, kAXDialogSubrole].contains(attributes.subrole)
            {
                elements.append(axUiElement)
            }
        }

        return elements
    }

}
