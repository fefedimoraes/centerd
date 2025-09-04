import AppKit

class OverlayWindowController: NSWindowController {
  private let components: Components

  private var selectedIndex: Int = 0 {
    didSet { OverlayWindowController.highlightSelected(selectedIndex, components) }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(windows: [WindowInfo]) throws {
    components = OverlayWindowController.setup(windows)
    super.init(window: components.overlayWindow)
  }

  public func moveForward() {
    selectedIndex = (selectedIndex + 1) % components.windows.count
  }

  public func moveBackwards() {
    selectedIndex = (selectedIndex - 1 + components.windows.count) % components.windows.count
  }

  private static func getOverlayWindow() -> NSWindow {
    guard let screenFrame = NSScreen.main?.frame else {
      fatalError("Screen Frame must be defined")
    }

    let overlayWindow = NSWindow(
      contentRect: screenFrame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    overlayWindow.level = .screenSaver
    overlayWindow.isOpaque = false
    overlayWindow.backgroundColor = .clear
    overlayWindow.ignoresMouseEvents = true
    overlayWindow.hasShadow = false

    return overlayWindow
  }

  private static func getBackgroundView() -> NSVisualEffectView {
    let backgroundView = NSVisualEffectView()

    backgroundView.material = .hudWindow
    backgroundView.blendingMode = .withinWindow
    backgroundView.state = .active
    backgroundView.wantsLayer = true
    backgroundView.layer?.cornerRadius = 20
    backgroundView.layer?.shadowColor = NSColor.black.cgColor
    backgroundView.layer?.shadowOpacity = 0.4
    backgroundView.layer?.shadowRadius = 20
    backgroundView.layer?.borderWidth = 1
    backgroundView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
    backgroundView.translatesAutoresizingMaskIntoConstraints = false

    return backgroundView
  }

  private static func getWindowRow() -> NSStackView {
    let stackView = NSStackView()

    stackView.orientation = .horizontal
    stackView.alignment = .centerY
    stackView.spacing = 40
    stackView.translatesAutoresizingMaskIntoConstraints = false

    return stackView
  }

  private static func getWindowView(_ windowInfo: WindowInfo) -> NSView {
    let container = NSView()
    let imageView = NSImageView()

    imageView.image = windowInfo.thumbnail()
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 8
    imageView.layer?.masksToBounds = true
    imageView.translatesAutoresizingMaskIntoConstraints = false

    container.wantsLayer = true
    container.layer?.cornerRadius = 12
    container.layer?.backgroundColor = NSColor.clear.cgColor
    container.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(imageView)

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 128),
      imageView.heightAnchor.constraint(equalToConstant: 128),

      imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
      imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
      imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
      imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
    ])

    return container
  }

  private static func getTitleTextField() -> NSTextField {
    let titleLabel = NSTextField(labelWithString: "")

    titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
    titleLabel.alignment = .center
    titleLabel.textColor = .secondaryLabelColor
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.maximumNumberOfLines = 1
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    return titleLabel
  }

  private static func highlightSelected(_ selectedIndex: Int, _ components: Components) {
    for (i, view) in components.windowRow.arrangedSubviews.enumerated() {
      let isSelected = (i == selectedIndex)
      let color = (isSelected ? NSColor.black.withAlphaComponent(0.5) : NSColor.clear).cgColor

      if let layer = view.layer {
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = layer.backgroundColor
        animation.toValue = color
        animation.duration = 0.15
        layer.add(animation, forKey: "backgroundColor")
        layer.backgroundColor = color  // set final value
      }

      if isSelected {
        components.titleTextField.stringValue = (try? components.windows[i].title()) ?? "Untitled"
      }
    }
  }

  private static func setup(_ windows: [WindowInfo]) -> Components {
    let overlayWindow = OverlayWindowController.getOverlayWindow()
    guard let contentView = overlayWindow.contentView else {
      preconditionFailure("Content View of overlay window is null.")
    }
    let backgroundView = OverlayWindowController.getBackgroundView()
    let windowRow = OverlayWindowController.getWindowRow()
    let titleTextField = OverlayWindowController.getTitleTextField()

    let components = Components(
      overlayWindow: overlayWindow,
      windowRow: windowRow,
      titleTextField: titleTextField,
      windows: windows
    )

    contentView.addSubview(backgroundView)
    backgroundView.addSubview(windowRow)
    backgroundView.addSubview(titleTextField)
    for window in windows.map({ OverlayWindowController.getWindowView($0) }) {
      windowRow.addArrangedSubview(window)
    }

    NSLayoutConstraint.activate([
      backgroundView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      backgroundView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),

      windowRow.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
      windowRow.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 40),

      titleTextField.topAnchor.constraint(equalTo: windowRow.bottomAnchor, constant: 16),
      titleTextField.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
      titleTextField.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -24),
      titleTextField.widthAnchor.constraint(lessThanOrEqualToConstant: 400),

      windowRow.leadingAnchor.constraint(
        greaterThanOrEqualTo: backgroundView.leadingAnchor, constant: 60),
      windowRow.trailingAnchor.constraint(
        lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -60),
    ])

    overlayWindow.makeKeyAndOrderFront(nil)

    OverlayWindowController.highlightSelected(0, components)

    return components
  }

  private struct Components {
    let overlayWindow: NSWindow
    let windowRow: NSStackView
    let titleTextField: NSTextField

    let windows: [WindowInfo]
  }
}
