import Cocoa

public struct WindowInfo {
  let id: CGWindowID
  let cgWindow: CGWindow
  let axUiElementWindow: AXUIElement
  let bounds: NSRect
  let isInCurrentSpace: Bool

  func getCenter() -> CGPoint {
    return CGPoint(x: bounds.midX, y: bounds.midY)
  }
}
