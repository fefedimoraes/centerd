import Cocoa

public protocol Accessibility {

    func isProcessTrusted() -> Bool

    func promptForAccessbility()

}

public class SystemAccessibility: Accessibility {

    public func isProcessTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    public func promptForAccessbility() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true
        ]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

}
