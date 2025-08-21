import Cocoa
import CoreGraphics
import Foundation

class TestCommand : CliCommand {

    private let delay: UInt32?

    init(delay: UInt32?) {
        self.delay = delay
    }

    func exec() -> Int32 {
        delay.sleep()

        guard let activeApplication = NSWorkspace.shared.frontmostApplication else {
            fputs("Failed to detect active application.\n", stderr)
            return EX_UNAVAILABLE
        }

        let allCgWindowsById  = CGWindow.windows(.excludeDesktopElements)
            .compactMap { $0.keyedById() }
            .toDictionary()

        do {
            let windowInfo = try getAllWindowInfo(pid: activeApplication.processIdentifier, cgWindowsById: allCgWindowsById)
            print(windowInfo)
        } catch {
            return EX_UNAVAILABLE
        }
        return EX_OK
    }

    private func getAllWindowInfo(pid: pid_t, cgWindowsById: [CGWindowID: CGWindow]) throws -> [WindowInfo] {
        return try AXUIElementCreateApplication(pid).getAllWindowsByPid(pid).compactMap { axUiElement in
            guard let id = try axUiElement.cgWindowId(), let cgWindow = cgWindowsById[id] else {
                return nil
            }
            return WindowInfo(id: id, cgWindow: cgWindow, axUiElementWindow: axUiElement)
        }
    }

    private struct WindowInfo {
        let id: CGWindowID
        let cgWindow: CGWindow
        let axUiElementWindow: AXUIElement
    }

}
