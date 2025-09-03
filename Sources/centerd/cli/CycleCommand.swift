import Cocoa
import CoreGraphics
import Foundation

class CycleCommand: CliCommand {

  private let appName: String
  private let step: Int
  private let tolerance: Double

  init(appName: String, step: Int, tolerance: Double) {
    self.appName = appName
    self.step = step
    self.tolerance = tolerance
  }

  func exec() -> Int32 {
    guard
      let application = NSWorkspace.shared.runningApplications.first(where: {
        $0.localizedName == appName
      })
    else {
      fputs("Could not find app. [App Name: \(appName)]", stderr)
      return EX_UNAVAILABLE
    }

    let allCgWindowsById = CGWindow.windows(.excludeDesktopElements)
      .compactMap { $0.keyedById() }
      .toDictionary()

    guard let mouseLocation = CGEvent(source: nil)?.location else {
      fputs("Failed to retrieve mouse location.\n", stderr)
      return EX_UNAVAILABLE
    }

    do {
      let windows = try getAllWindowInfo(
        pid: application.processIdentifier, cgWindowsById: allCgWindowsById)
      guard
        let window = getWindow(
          application: application, mouseLocation: mouseLocation, windows: windows)
      else {
        fputs("Failed to determine window to select.\n", stderr)
        return EX_UNAVAILABLE
      }

      if !application.isActive {
        guard application.activate() else {
          fputs("Failed to activate application.\n", stderr)
          return EX_UNAVAILABLE
        }
      }
      window.axUiElementWindow.focusWindow()
      CGWarpMouseCursorPosition(window.getCenter())
      return EX_OK
    } catch {
      fputs("Failed to retrieve windows.\n\(error)", stderr)
      return EX_UNAVAILABLE
    }
  }

  private func getClosestWindow(mouseLocation: CGPoint, windows: [WindowInfo]) -> WindowInfo? {
    return windows.min(by: { lhs, rhs in
      lhs.isInCurrentSpace == rhs.isInCurrentSpace
        ? mouseLocation.distance(point: lhs.getCenter())
          < mouseLocation.distance(point: rhs.getCenter())
        : lhs.isInCurrentSpace
    })
  }

  private func getNextWindow(mouseLocation: CGPoint, windows: [WindowInfo]) -> WindowInfo? {
    if let selectedIndex = windows.firstIndex(where: {
      mouseLocation.distance(point: $0.getCenter()) < tolerance
    }) {
      let nextIndex = ((selectedIndex + step) % windows.count + windows.count) % windows.count
      return windows[nextIndex]
    }
    return nil
  }

  private func getWindow(
    application: NSRunningApplication, mouseLocation: CGPoint, windows: [CGWindowID: WindowInfo]
  ) -> WindowInfo? {
    let sortedWindows = windows.values.sorted(by: { $0.id < $1.id })
    if !application.isActive {
      return getClosestWindow(mouseLocation: mouseLocation, windows: sortedWindows)
    }
    return getNextWindow(mouseLocation: mouseLocation, windows: sortedWindows)
      ?? getClosestWindow(mouseLocation: mouseLocation, windows: sortedWindows)
  }

  private func getAllWindowInfo(pid: pid_t, cgWindowsById: [CGWindowID: CGWindow]) throws
    -> [CGWindowID: WindowInfo]
  {
    let app = AXUIElementCreateApplication(pid)
    let currentSpaceWindows: Set<CGWindowID> = try app.getCurrentSpaceWindows().compactMap {
      axUiElement in
      guard let id = try axUiElement.cgWindowId() else {
        return nil
      }
      return id
    }.toSet()

    return try app.getAllWindowsByPid(pid).compactMap { axUiElement in
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
    }.map { ($0.id, $0) }.toDictionary()
  }

  private struct WindowInfo {
    let id: CGWindowID
    let cgWindow: CGWindow
    let axUiElementWindow: AXUIElement
    let bounds: NSRect
    let isInCurrentSpace: Bool

    func getCenter() -> CGPoint {
      return CGPoint(x: bounds.midX, y: bounds.midY)
    }
  }

}
