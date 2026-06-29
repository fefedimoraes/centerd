import Cocoa
import SwiftUI

/// A borderless, non-activating floating panel that hosts the switcher HUD.
///
/// It must never become key or main: doing so would steal focus from the target application
/// and break the window-raise on commit. Cycling is driven entirely by the event tap, so the
/// panel ignores mouse events.
public final class SwitcherPanel: NSPanel {

    private let model: SwitcherViewModel
    private let hostingView: NSHostingView<SwitcherView>

    init(model: SwitcherViewModel) {
        self.model = model
        self.hostingView = NSHostingView(rootView: SwitcherView(model: model))

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        ignoresMouseEvents = true

        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        visualEffect.translatesAutoresizingMaskIntoConstraints = false

        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(visualEffect)
        container.addSubview(hostingView)
        NSLayoutConstraint.activate([
            visualEffect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            visualEffect.topAnchor.constraint(equalTo: container.topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        contentView = container
    }

    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }

    /// Sizes the panel to fit its content, centers it on the display containing the mouse,
    /// and fades it in.
    func present() {
        let fitting = hostingView.fittingSize
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: fitting.width, height: fitting.height)

        let origin = NSPoint(
            x: visibleFrame.midX - fitting.width / 2,
            y: visibleFrame.midY - fitting.height / 2
        )
        setFrame(NSRect(origin: origin, size: fitting), display: true)

        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1
        }
    }

    /// Fades the panel out and removes it from screen.
    func dismiss() {
        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.1
                animator().alphaValue = 0
            },
            completionHandler: { [weak self] in
                self?.orderOut(nil)
            }
        )
    }

}
