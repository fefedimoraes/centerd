import Cocoa
import CoreGraphics

/// A live, actionable reference to a single application window.
///
/// Unlike `AXAttributes` (an immutable, `Hashable` snapshot used for discovery and
/// de-duplication), `Window` retains the underlying `AXUIElement` so we can read its
/// current geometry, raise it, and center the mouse on it at commit time.
public struct Window: Identifiable {

    /// The `CGWindowID`, used as a stable identity for de-duplication and `Identifiable`.
    public let id: CGWindowID

    /// The live accessibility element. As a `CFType`, it is retained for this value's lifetime.
    let element: AXUIElement

    /// The process identifier of the owning application.
    let pid: pid_t

    /// The window title, if available.
    let title: String?

}

extension Window {

    /// The window's current frame in Accessibility coordinates (top-left origin), or `nil`
    /// if its position or size cannot be read. Geometry is read on demand because windows move.
    func frame() -> CGRect? {
        guard let origin = Window.copyValue(element, kAXPositionAttribute, .cgPoint, CGPoint.self),
            let size = Window.copyValue(element, kAXSizeAttribute, .cgSize, CGSize.self)
        else {
            return nil
        }
        return CGRect(origin: origin, size: size)
    }

    /// Brings this window to the front within its application.
    @discardableResult
    func raise() -> Bool {
        return AXUIElementPerformAction(element, kAXRaiseAction as CFString) == .success
    }

    /// Reads an `AXValue`-wrapped attribute (e.g. position or size) and unwraps it into `T`.
    private static func copyValue<T>(
        _ element: AXUIElement, _ attribute: String, _ type: AXValueType, _ valueType: T.Type
    ) -> T? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success,
            let value = ref, CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }

        let result = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { result.deallocate() }
        guard AXValueGetValue(value as! AXValue, type, result) else { return nil }
        return result.pointee
    }

}
