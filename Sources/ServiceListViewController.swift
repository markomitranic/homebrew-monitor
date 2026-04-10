import AppKit

class ServiceListViewController: NSViewController {
    private let scrollView = NSScrollView()
    private let stackView = NSStackView()
    private let headerLabel = NSTextField(labelWithString: "Homebrew Services")
    private let messageLabel = NSTextField(labelWithString: "")
    private var serviceRows: [ServiceRowView] = []

    var onToggleService: ((String, Bool) -> Void)?
    var onRefresh: (() -> Void)?
    var onQuit: (() -> Void)?

    private let popoverWidth: CGFloat = 280
    private let rowHeight: CGFloat = 36
    private let headerHeight: CGFloat = 40
    private let footerHeight: CGFloat = 36
    private let maxHeight: CGFloat = 420

    override func loadView() {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        self.view = container

        setupHeader()
        setupMessageLabel()
        setupScrollView()
        setupFooter()
    }

    private func setupHeader() {
        let header = NSView()
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.textColor = .secondaryLabelColor
        header.addSubview(headerLabel)

        let refreshButton = NSButton(title: "", target: self, action: #selector(refreshClicked))
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")
        refreshButton.bezelStyle = .inline
        refreshButton.isBordered = false
        refreshButton.imagePosition = .imageOnly
        header.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: headerHeight),

            headerLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            headerLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            refreshButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            refreshButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
    }

    private func setupMessageLabel() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 12)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.alignment = .center
        messageLabel.isHidden = true
        view.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: headerHeight + 20),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        view.addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 0

        scrollView.documentView = stackView

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: headerHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
        ])
    }

    private func setupFooter() {
        let separator = NSBox()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator
        view.addSubview(separator)

        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quitClicked))
        quitButton.translatesAutoresizingMaskIntoConstraints = false
        quitButton.bezelStyle = .inline
        quitButton.isBordered = false
        quitButton.font = .systemFont(ofSize: 12)
        quitButton.contentTintColor = .secondaryLabelColor
        view.addSubview(quitButton)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -footerHeight),

            quitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),

            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor),
        ])
    }

    func updateServices(_ services: [BrewServiceInfo]) {
        messageLabel.isHidden = true
        scrollView.isHidden = false

        // Remove old rows
        for row in serviceRows {
            stackView.removeArrangedSubview(row)
            row.removeFromSuperview()
        }
        serviceRows.removeAll()

        if services.isEmpty {
            showMessage("No Homebrew services found")
            updatePreferredSize(serviceCount: 0)
            return
        }

        for service in services {
            let row = ServiceRowView(service: service)
            row.onToggle = { [weak self] name, shouldStart in
                self?.onToggleService?(name, shouldStart)
            }
            stackView.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            serviceRows.append(row)
        }

        updatePreferredSize(serviceCount: services.count)
    }

    func setServiceLoading(_ name: String, isLoading: Bool) {
        serviceRows.first { $0.serviceName == name }?.setLoading(isLoading)
    }

    func showError(_ message: String) {
        showMessage(message)
    }

    func showServiceError(_ name: String, message: String) {
        // Brief inline error — will be cleared on next refresh
        if let row = serviceRows.first(where: { $0.serviceName == name }) {
            row.setLoading(false)
        }
    }

    private func showMessage(_ text: String) {
        messageLabel.stringValue = text
        messageLabel.isHidden = false
        scrollView.isHidden = true
        updatePreferredSize(serviceCount: 0)
    }

    private func updatePreferredSize(serviceCount: Int) {
        let contentHeight: CGFloat
        if serviceCount == 0 {
            contentHeight = headerHeight + 60 + footerHeight
        } else {
            contentHeight = headerHeight + CGFloat(serviceCount) * rowHeight + footerHeight
        }
        let height = min(contentHeight, maxHeight)
        preferredContentSize = NSSize(width: popoverWidth, height: height)
    }

    @objc private func refreshClicked() {
        onRefresh?()
    }

    @objc private func quitClicked() {
        onQuit?()
    }
}
