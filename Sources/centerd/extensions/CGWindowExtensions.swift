import Cocoa

public typealias CGWindow = [CFString: Any]

extension CGWindow {

  public static func windows(_ option: CGWindowListOption) -> [CGWindow] {
    return CGWindowListCopyWindowInfo(option, kCGNullWindowID) as! [CGWindow]
  }

  public func id() -> CGWindowID? {
    return value(kCGWindowNumber, CGWindowID.self)
  }

  public func keyedById() -> (CGWindowID, CGWindow)? {
    guard let id = id() else { return nil }
    return (id, self)
  }

  public func bounds() -> NSRect? {
    if let windowBounds = value(kCGWindowBounds, CFDictionary.self) {
      return NSRect(dictionaryRepresentation: windowBounds)
    }
    return nil
  }

  public func title() -> String? {
    return value(kCGWindowName, String.self)
  }

  private func value<T>(_ key: CFString, _ type: T.Type) -> T? {
    return self[key] as? T
  }

}
