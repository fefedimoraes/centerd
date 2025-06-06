import Cocoa
import CoreGraphics
import Foundation

class ActiveWindowCenter: CliCommand {

    func exec() -> Int32 {
        if let delayArgumentValue = CommandLine.arguments.getArgumentValue(argName: "--delay"),
           let delay = UInt32(delayArgumentValue) {
            sleep(delay)
        }

        guard let activeApplication = NSWorkspace.shared.frontmostApplication else {
            fputs("Failed to detect active application.\n", stderr)
            return EX_UNAVAILABLE
        }

        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [NSDictionary] else {
            fputs("Failed to retrieve window list.\n", stderr)
            return EX_UNAVAILABLE
        }

        guard let activeWindowInfo = windowList.first(where: {
            $0[kCGWindowOwnerPID] as? pid_t == activeApplication.processIdentifier
        }) else {
            fputs("Failed to retrieve active window.\n", stderr)
            return EX_UNAVAILABLE
        }

        guard let activeWindowBounds = activeWindowInfo[kCGWindowBounds] as? NSDictionary,
              let activeWindowRectangle = CGRect(dictionaryRepresentation: activeWindowBounds) else {
            fputs("Failed to retrieve active window bounds.\n", stderr)
            return EX_UNAVAILABLE
        }

        let activeWindowCenter = CGPoint(x: activeWindowRectangle.midX, y: activeWindowRectangle.midY)
        let warpMouseCursorResult = CGWarpMouseCursorPosition(activeWindowCenter)

        if warpMouseCursorResult != CGError.success {
            fputs("Failed to warp mouse cursor. [Error: \(String(describing: warpMouseCursorResult))]\n", stderr)
            return EX_UNAVAILABLE
        }

        return EX_OK
    }
}
