import Cocoa

extension NSRunningApplication {

  public func getWindows() throws -> [WindowInfo] {
    let application = AXUIElementCreateApplication(processIdentifier)

    let cgWindowsById = CGWindow.windows(.excludeDesktopElements)
      .compactMap { $0.keyedById() }
      .toDictionary()

    let currentSpaceWindows: Set<CGWindowID> = try application.getCurrentSpaceWindows().compactMap {
      axUiElement in
      guard let id = try axUiElement.cgWindowId() else {
        return nil
      }
      return id
    }.toSet()

    return try application.getAllWindowsByPid(processIdentifier).compactMap { axUiElement in
      guard let id = try axUiElement.cgWindowId(), let cgWindow = cgWindowsById[id],
        let bounds = cgWindow.bounds()
      else {
        return nil
      }
      return WindowInfo(
        id: id,
        cgWindow: cgWindow,
        axUiElementWindow: axUiElement,
        bounds: bounds,
        isInCurrentSpace: currentSpaceWindows.contains(id)
      )
    }
  }

  public func getWindowToFocus(
    _ reference: CGPoint,
    _ tolerance: Double,
    _ step: Int
  ) throws -> WindowInfo? {
    let windows = try getWindows()
    if !isActive {
      return NSRunningApplication.getClosestWindow(windows, reference)
    }
    return NSRunningApplication.getNextWindow(
      windows.sorted(by: { $0.id < $1.id }), reference, tolerance, step
    ) ?? NSRunningApplication.getClosestWindow(windows, reference)
  }

  private static func getClosestWindow(
    _ windows: [WindowInfo],
    _ reference: CGPoint
  ) -> WindowInfo? {
    return windows.min(by: { lhs, rhs in
      lhs.isInCurrentSpace == rhs.isInCurrentSpace
        ? reference.distance(point: lhs.getCenter()) < reference.distance(point: rhs.getCenter())
        : lhs.isInCurrentSpace
    })
  }

  private static func getNextWindow(
    _ windows: [WindowInfo],
    _ reference: CGPoint,
    _ tolerance: Double,
    _ step: Int
  ) -> WindowInfo? {
    if let selectedIndex = windows.firstIndex(where: {
      reference.distance(point: $0.getCenter()) < tolerance
    }) {
      return windows[((selectedIndex + step) % windows.count + windows.count) % windows.count]
    }
    return nil
  }

}
