import Cocoa

extension AXUIElement {

    public func role() throws -> String? {
        return try getAttribute(kAXRoleAttribute, String.self)
    }

    public func subrole() throws -> String? {
        return try getAttribute(kAXSubroleAttribute, String.self)
    }

    func cgWindowId() throws -> CGWindowID? {
        var id = CGWindowID(0)
        return try withThrow(_AXUIElementGetWindow(self, &id), &id)
    }

    public func getCurrentSpaceWindows() throws -> [AXUIElement] {
        let windows = try getAttribute(kAXWindowsAttribute, [AXUIElement].self)
        if let windows, !windows.isEmpty {
            // bug in macOS: sometimes the OS returns multiple duplicate windows (e.g. Mail.app starting at login)
            let uniqueWindows = Array(Set(windows))
            if !uniqueWindows.isEmpty {
                return uniqueWindows
            }
        }
        return []
    }

    public func getAllWindowsByPid(_ pid: pid_t) throws -> [AXUIElement] {
        return AXUIElement.getWindowsByBruteForce(pid)
    }

    public func focusWindow() {
        AXUIElementPerformAction(self, kAXRaiseAction as CFString)
    }

    private static func getWindowsByBruteForce(_ pid: pid_t) -> [AXUIElement] {
        return (0 ..< 1000).parallelCompactMap { getWindowByBruteForce(pid, index: $0 as AXUIElementID) }
    }

    private static func getWindowByBruteForce(_ pid: pid_t, index: AXUIElementID) -> AXUIElement? {
        // we use this to call _AXUIElementCreateWithRemoteToken
        // tests showed that this remoteToken is 20 bytes: 4 + 4 + 4 + 8; the order of bytes matters
        var remoteToken = Data(count: 20)
        remoteToken.replaceSubrange(0..<4, with: withUnsafeBytes(of: pid) { Data($0) })
        remoteToken.replaceSubrange(4..<8, with: withUnsafeBytes(of: Int32(0)) { Data($0) })
        remoteToken.replaceSubrange(8..<12, with: withUnsafeBytes(of: Int32(0x636f636f)) { Data($0) })
        remoteToken.replaceSubrange(12..<20, with: withUnsafeBytes(of: index) { Data($0) })

        if let axUiElement = _AXUIElementCreateWithRemoteToken(remoteToken as CFData)?.takeRetainedValue(),
           let subrole = try? axUiElement.subrole(),
           subrole == kAXStandardWindowSubrole || subrole == kAXDialogSubrole {
            return axUiElement
        }

        return nil
    }

    private func getAttribute<T>(_ key: String, _ _: T.Type) throws -> T? {
        var value: AnyObject?
        return try withThrow(AXUIElementCopyAttributeValue(self, key as CFString, &value), &value) as? T
    }

    private func withThrow<T>(_ result: AXError, _ successValue: inout T) throws -> T? {
        switch result {
        case .success: return successValue
            // .cannotComplete can happen if the app is unresponsive; we throw in that case to retry until the call succeeds
        case .cannotComplete: throw AxError.runtimeError
            // for other errors it's pointless to retry
        default: return nil
        }
    }

    private enum AxError : Error {
        case runtimeError
    }

    /// tests have shown that this ID has a range going from 0 to probably UInt.MAX
    /// it starts at 0 for each app, and increments over time, for each new UI element
    /// this means that long-lived apps (e.g. Finder) may have high IDs
    /// we don't know how high it can go, and if it wraps around
    typealias AXUIElementID = UInt64

}
