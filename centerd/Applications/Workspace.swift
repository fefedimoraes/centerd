import Cocoa
import SwiftUI

public enum ApplicationActivationPolicy {

    /// The application is an ordinary app that appears in the Dock and may have a user interface.
    /// This is the default for bundled apps, unless overridden in the Info.plist.
    case regular

    /// The application does not appear in the Dock and does not have a menu bar,
    /// but it may be activated programmatically or by clicking on one of its windows.
    /// This corresponds to `LSUIElement=1` in the `Info.plist`.
    case accessory

    /// The application does not appear in the Dock and may not create windows or be activated.
    /// This corresponds to `LSBackgroundOnly=1` in the `Info.plist`.
    /// This is also the default for unbundled executables that do not have Info.plists.
    case prohibited

}

public struct Application {

    /// Indicates that the process is an exited application.
    let isTerminated: Bool

    /// Indicates that the process is finished launching.
    /// Some applications do not post this notification and so are never reported as finished launching.
    let finishedLaunching: Bool

    /// Indicates whether the application is currently hidden.
    let isHidden: Bool

    /// Indicates whether the application is currently frontmost.
    let isActive: Bool

    /// Indicates whether the application currently owns the menu bar.
    let ownsMenuBar: Bool

    /// Indicates the activation policy of the application.
    let activationPolicy: ApplicationActivationPolicy

    /// Indicates the name of the application.
    /// This is dependent on the current localization of the referenced app,
    /// and is suitable for presentation to the user.
    let localizedName: String?

    /// Indicates the `CFBundleIdentifier` of the application, or nil if the application does not have an `Info.plist`.
    let bundleIdentifier: String?

    /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
    let bundleURL: URL?

    /// Indicates the URL to the application's executable.
    let executableURL: URL?

    /// Indicates the process identifier (pid) of the application.
    /// Do not rely on this for comparing processes.
    /// @note Not all applications have a pid. Applications without a pid return -1 from this method.
    /// An application's pid may change if it is automatically terminated.
    let processIdentifier: pid_t

    /// Indicates the date when the application was launched.
    /// This property is not available for all applications.
    /// Specifically, it is not available for applications that were launched without going through `LaunchServices`.
    let launchDate: Date?

    /// @return The icon of the application.
    let icon: Image?

    /// Indicates the executing processor architecture for the application.
    let executableArchitecture: Int

    /// Attempts to activate the receiver.
    /// @return `YES` if the request to activate was successfully sent;
    /// `NO` if not (for example, if the application has quit, or is of a type that cannot be activated).
    let activate: () -> Bool

}

extension ApplicationActivationPolicy {

    init(_ policy: NSApplication.ActivationPolicy) {
        switch policy {
        case .regular: self = .regular
        case .accessory: self = .accessory
        case .prohibited: self = .prohibited
        @unknown default: fatalError("Cannot convert \(NSApplication.ActivationPolicy.self) to \(Self.self)")
        }
    }

}

extension Application {

    init(_ app: NSRunningApplication) {
        self.isTerminated = app.isTerminated
        self.finishedLaunching = app.isFinishedLaunching
        self.isHidden = app.isHidden
        self.isActive = app.isActive
        self.ownsMenuBar = app.ownsMenuBar
        self.activationPolicy = ApplicationActivationPolicy(
            app.activationPolicy
        )
        self.localizedName = app.localizedName
        self.bundleIdentifier = app.bundleIdentifier
        self.bundleURL = app.bundleURL
        self.executableURL = app.executableURL
        self.processIdentifier = app.processIdentifier
        self.launchDate = app.launchDate
        self.icon = Image(nsImage: app.icon)
        self.executableArchitecture = app.executableArchitecture
        self.activate = { app.activate() }
    }

}

public protocol Workspace {

    /// @return An array of `Application`s representing currently running applications.
    func getRunningApplications() -> [Application]

    /// @return An array of currently running applications with the given bundle identifier, or an empty array if no apps match.
    func getRunningApplications(withBundleIdentifier bundleIdentifier: String) -> [Application]

}

public class SystemWorkspace: Workspace {

    public func getRunningApplications() -> [Application] {
        return NSWorkspace.shared.runningApplications.map { Application($0) }
    }

    public func getRunningApplications(withBundleIdentifier bundleIdentifier: String) -> [Application] {
        return NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).map { Application($0) }
    }

}
