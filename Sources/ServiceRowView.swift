import AppKit

class ToggleSwitch: NSView {
    var isOn: Bool = false {
        didSet { needsDisplay = true }
    }
    var isEnabled: Bool = true {
        didSet {
            alphaValue = isEnabled ? 1.0 : 0.5
        }
    }
    var onToggle: ((Bool) -> Void)?

    private let trackWidth: CGFloat = 36
    private let trackHeight: CGFloat = 20
    private let knobInset: CGFloat = 2

    override var intrinsicContentSize: NSSize {
        NSSize(width: trackWidth, height: trackHeight)
    }

    override init(frame: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 36, height: 20))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bounds = self.bounds

        // Track
        let trackRect = NSRect(
            x: (bounds.width - trackWidth) / 2,
            y: (bounds.height - trackHeight) / 2,
            width: trackWidth,
            height: trackHeight
        )
        let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: trackHeight / 2, yRadius: trackHeight / 2)

        if isOn {
            NSColor.systemGreen.setFill()
        } else {
            NSColor.systemGray.setFill()
        }
        trackPath.fill()

        // Knob
        let knobDiameter = trackHeight - knobInset * 2
        let knobX: CGFloat
        if isOn {
            knobX = trackRect.maxX - knobInset - knobDiameter
        } else {
            knobX = trackRect.minX + knobInset
        }
        let knobRect = NSRect(
            x: knobX,
            y: trackRect.minY + knobInset,
            width: knobDiameter,
            height: knobDiameter
        )
        let knobPath = NSBezierPath(ovalIn: knobRect)
        NSColor.white.setFill()
        knobPath.fill()
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        isOn.toggle()
        onToggle?(isOn)
    }
}

class ServiceRowView: NSView {
    let serviceName: String
    private let dot = NSView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let toggle = ToggleSwitch()
    private var isLoading = false

    var onToggle: ((String, Bool) -> Void)?

    init(service: BrewServiceInfo) {
        self.serviceName = service.name
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        setupDot(running: service.running)
        setupNameLabel(name: service.name)
        setupToggle(running: service.running, isRoot: service.user == "root")
        layoutRow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func setupDot(running: Bool) {
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 4
        dot.layer?.backgroundColor = running ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor
        addSubview(dot)
    }

    private func setupNameLabel(name: String) {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.stringValue = name
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(nameLabel)
    }

    private func setupToggle(running: Bool, isRoot: Bool) {
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.isOn = running
        toggle.isEnabled = !isRoot
        toggle.onToggle = { [weak self] newState in
            guard let self else { return }
            self.onToggle?(self.serviceName, newState)
        }
        if isRoot {
            toggle.toolTip = "Requires root — cannot toggle from menu bar"
        }
        addSubview(toggle)
    }

    private func layoutRow() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 36),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),

            nameLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
            toggle.widthAnchor.constraint(equalToConstant: 36),
            toggle.heightAnchor.constraint(equalToConstant: 20),

            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),
        ])
    }

    func setLoading(_ loading: Bool) {
        isLoading = loading
        toggle.isEnabled = !loading
        dot.layer?.backgroundColor = loading ? NSColor.systemOrange.cgColor :
            (toggle.isOn ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor)
    }
}
