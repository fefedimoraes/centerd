import AppKit

class OverlayWindowController: NSWindowController {
  private let overlayWindow: NSWindow
  private let windows: [WindowInfo]
  private let stackView = NSStackView()

  private var selectedIndex: Int = 0 {
    didSet { highlightSelected() }
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
      defer: false,
    )
    overlayWindow.level = .screenSaver
    overlayWindow.isOpaque = false
    overlayWindow.backgroundColor = .clear
    overlayWindow.ignoresMouseEvents = true
    overlayWindow.hasShadow = false

    stackView.orientation = .horizontal
    stackView.alignment = .centerY
    stackView.spacing = 20
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

    let windowContainers = try windows.map { window in
      let label = NSTextField(labelWithString: try window.title() ?? "Untitled")
      let container = NSStackView()
      container.orientation = .vertical
      container.alignment = .centerX
      container.spacing = 0

      if let thumbnail = window.thumbnail() {
        let imageView = NSImageView(image: thumbnail)
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 8
        imageView.layer?.borderWidth = 2
        imageView.layer?.borderColor = NSColor.clear.cgColor
        container.addArrangedSubview(imageView)

        NSLayoutConstraint.activate([
          imageView.widthAnchor.constraint(equalToConstant: 200),
          imageView.heightAnchor.constraint(equalToConstant: 150),
        ])
      }

      container.addArrangedSubview(label)

      return container
    }

    for windowContainer in windowContainers {
      stackView.addArrangedSubview(windowContainer)
    }

    contentView.addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    selectedIndex = 0
  }

  private func highlightSelected() {
    for (i, container) in stackView.arrangedSubviews.enumerated() {
      if let imageView = (container as? NSStackView)?.arrangedSubviews.first as? NSImageView {
        imageView.layer?.borderColor =
          (i == selectedIndex) ? NSColor.systemBlue.cgColor : NSColor.clear.cgColor
      }
    }
  }
}
