import Cocoa
import CoreFoundation

/// for some reason, this attribute is missing from ApplicationServices.HIServices.AXUIElement
/// returns the CGWindowID of the provided AXUIElement
/// * macOS 10.10+
@_silgen_name("_AXUIElementGetWindow") @discardableResult
func _AXUIElementGetWindow(_ axUiElement: AXUIElement, _ wid: UnsafeMutablePointer<CGWindowID>)
  -> AXError

/// returns an AXUIElement given a Data object. Data object should hold:
/// - pid (4 bytes)
/// - 0 (4 bytes)
/// - 0x636f636f (4 bytes)
/// - AXUIElementID (8 bytes)
@_silgen_name("_AXUIElementCreateWithRemoteToken") @discardableResult
func _AXUIElementCreateWithRemoteToken(_ data: CFData) -> Unmanaged<AXUIElement>?
