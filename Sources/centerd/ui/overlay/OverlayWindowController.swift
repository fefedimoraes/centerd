import AppKit

class OverlayWindowController: NSWindowController {
  private let windows: [WindowInfo]
  private let overlayWindow: NSWindow
  private let stackView = NSStackView()
  private let backgroundView = NSVisualEffectView()
  private let titleLabel = NSTextField(labelWithString: "")

  private var selectedIndex: Int = 0 {
    didSet { highlightSelected(animated: true) }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(windows: [WindowInfo]) throws {
    self.windows = windows
    guard let screenFrame = NSScreen.main?.frame else {
      fatalError("Screen Frame must be defined")
    }
    overlayWindow = NSWindow(
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

    stackView.orientation = .horizontal
    stackView.alignment = .centerY
    stackView.spacing = 40
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(window: overlayWindow)
    try setup()
  }

  public func moveForward() {
    selectedIndex = (selectedIndex + 1) % windows.count
  }

  public func moveBackwards() {
    selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
  }

  private func setup() throws {
    guard let contentView = overlayWindow.contentView else { return }

    backgroundView.material = .hudWindow
    backgroundView.blendingMode = .withinWindow
    backgroundView.state = .active
    backgroundView.wantsLayer = true
    backgroundView.layer?.cornerRadius = 20
    backgroundView.layer?.shadowColor = NSColor.black.cgColor
    backgroundView.layer?.shadowOpacity = 0.4
    backgroundView.layer?.shadowRadius = 20
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(backgroundView)

    // Build thumbnails row
    for window in windows {
      // Thumbnail image
      let imageView = NSImageView()
      imageView.image = window.thumbnail()
      imageView.imageScaling = .scaleProportionallyUpOrDown
      imageView.wantsLayer = true
      imageView.layer?.cornerRadius = 8
      imageView.layer?.masksToBounds = true
      imageView.translatesAutoresizingMaskIntoConstraints = false

      // Container with padding
      let container = NSView()
      container.wantsLayer = true
      container.layer?.cornerRadius = 12
      container.layer?.backgroundColor = NSColor.clear.cgColor
      container.translatesAutoresizingMaskIntoConstraints = false

      container.addSubview(imageView)

      NSLayoutConstraint.activate([
        // Thumbnail fixed size
        imageView.widthAnchor.constraint(equalToConstant: 128),
        imageView.heightAnchor.constraint(equalToConstant: 128),

        // Thumbnail inset inside container (padding = 8)
        imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
        imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
        imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
      ])

      stackView.addArrangedSubview(container)
    }

    backgroundView.addSubview(stackView)

    // Title label (for selected window only)
    titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
    titleLabel.alignment = .center
    titleLabel.textColor = .secondaryLabelColor
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.maximumNumberOfLines = 1
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.addSubview(titleLabel)

    // Layout: background centered slightly below middle
    NSLayoutConstraint.activate([
      backgroundView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      backgroundView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),

      stackView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
      stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 40),

      titleLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
      titleLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -24),

      stackView.leadingAnchor.constraint(
        greaterThanOrEqualTo: backgroundView.leadingAnchor, constant: 60),
      stackView.trailingAnchor.constraint(
        lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -60),
      titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
    ])
    // Show overlay window
    overlayWindow.makeKeyAndOrderFront(nil)

    selectedIndex = 0
  }

  private func highlightSelected(animated: Bool) {
    for (i, view) in stackView.arrangedSubviews.enumerated() {
      let isSelected = (i == selectedIndex)

      let bgColor: CGColor =
        isSelected
        ? NSColor.black.withAlphaComponent(0.4).cgColor
        : NSColor.clear.cgColor

      if animated {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.15
          view.layer?.backgroundColor = bgColor
        }
      } else {
        view.layer?.backgroundColor = bgColor
      }

      if isSelected {
        titleLabel.stringValue = (try? windows[i].title()) ?? "Untitled"
      }
    }
  }
}
