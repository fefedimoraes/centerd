import Cocoa

public struct WindowInfo {
  let application: NSRunningApplication
  let id: CGWindowID
  let cgWindow: CGWindow
  let axUiElementWindow: AXUIElement

  let isInCurrentSpace: Bool

  func center() -> CGPoint? {
    guard let bounds = cgWindow.bounds() else { return nil }
    return CGPoint(x: bounds.midX, y: bounds.midY)
  }

  func title() throws -> String? {
    if let axTitle = try axUiElementWindow.title(), !axTitle.isEmpty {
      return axTitle
    }

    if let cgTitle = cgWindow.title(), !cgTitle.isEmpty {
      return cgTitle
    }

    return application.localizedName
  }

  func thumbnail() -> NSImage? {
    guard let bounds = cgWindow.bounds() else { return nil }
    if let cgImage = CGWindowListCreateImage(bounds, .optionIncludingWindow, id, .bestResolution) {
      return NSImage(cgImage: cgImage, size: NSZeroSize)
    }
    return nil
  }
}
