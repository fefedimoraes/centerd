import AppKit

class Daemon {
  public func run() throws {
    guard let applicationName = CommandLine.arguments.dropFirst().first else { return }
    guard let windows = try NSWorkspace.shared.getRunningApplication(applicationName)?.getWindows(),
      !windows.isEmpty
    else { return }

    let overlayWindowController = try OverlayWindowController(windows: windows)
    overlayWindowController.showWindow(self)
    Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
      overlayWindowController.moveForward()
    }
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))
  }
}

try Daemon().run()
