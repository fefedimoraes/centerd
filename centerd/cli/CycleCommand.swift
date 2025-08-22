import Cocoa
import CoreGraphics
import Foundation

class CycleCommand : CliCommand {

    private let delay: UInt32?
    private let tolerance: Double
    private let step: Int

    init(delay: UInt32?, tolerance: Double, step: Int) {
        self.delay = delay
        self.tolerance = tolerance
        self.step = step
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

        guard let mouseLocation = CGEvent(source: nil)?.location else {
            fputs("Failed to retrieve mouse location.\n", stderr)
            return EX_UNAVAILABLE
        }

        do {
            let windowInfoById = try getAllWindowInfo(pid: activeApplication.processIdentifier, cgWindowsById: allCgWindowsById)
            let windowInfoSortedById = windowInfoById.values.sorted(by: { $0.id < $1.id })
            if let selectedIndex = windowInfoSortedById.firstIndex(where: { mouseLocation.distance(point: $0.getCenter()) < tolerance }) {
                let nextWindow = windowInfoSortedById[(selectedIndex + step) % windowInfoSortedById.count]
                nextWindow.axUiElementWindow.focusWindow()
                CGWarpMouseCursorPosition(nextWindow.getCenter())
                return EX_OK
            }

            guard let closestWindow = windowInfoSortedById.min(by: { lhs, rhs in
                lhs.isInCurrentSpace == rhs.isInCurrentSpace
                ? mouseLocation.distance(point: lhs.getCenter()) < mouseLocation.distance(point: rhs.getCenter())
                : lhs.isInCurrentSpace
            }) else {
                fputs("Failed to get closest window.\n", stderr)
                return EX_UNAVAILABLE
            }
            closestWindow.axUiElementWindow.focusWindow()
            CGWarpMouseCursorPosition(closestWindow.getCenter())
            return EX_OK
        } catch {
            fputs("Failed to focus window.\n\(error)", stderr)
            return EX_UNAVAILABLE
        }
    }

    private func getAllWindowInfo(pid: pid_t, cgWindowsById: [CGWindowID: CGWindow]) throws -> [CGWindowID: WindowInfo] {
        let app = AXUIElementCreateApplication(pid)
        let currentSpaceWindows: Set<CGWindowID> = try app.getCurrentSpaceWindows().compactMap { axUiElement in
            guard let id = try axUiElement.cgWindowId() else {
                return nil
            }
            return id
        }.toSet()

        return try app.getAllWindowsByPid(pid).compactMap { axUiElement in
            guard let id = try axUiElement.cgWindowId(), let cgWindow = cgWindowsById[id], let bounds = cgWindow.bounds() else {
                return nil
            }
            return WindowInfo(
                id: id,
                cgWindow: cgWindow,
                axUiElementWindow: axUiElement,
                bounds: bounds,
                isInCurrentSpace: currentSpaceWindows.contains(id),
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
