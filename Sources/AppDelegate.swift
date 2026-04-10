import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let serviceManager = BrewServiceManager()
    private let listController = ServiceListViewController()
    private var services: [BrewServiceInfo] = []
    private var refreshTimer: Timer?
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = drawStatusIcon(active: false)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }

        popover.contentViewController = listController
        popover.behavior = .transient
        popover.delegate = self

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            self.popover.performClose(nil)
        }

        listController.onToggleService = { [weak self] name, shouldStart in
            self?.toggleService(name, shouldStart: shouldStart)
        }

        listController.onRefresh = { [weak self] in
            self?.refreshServices()
        }

        listController.onQuit = {
            NSApp.terminate(nil)
        }

        refreshServices()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshServices()
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            refreshServices()
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)

            clickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] _ in
                self?.popover.performClose(nil)
            }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    private func showContextMenu() {
        if popover.isShown { popover.performClose(nil) }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshClicked), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Homebrew Monitor", action: #selector(quitClicked), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    @objc private func refreshClicked() {
        refreshServices()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }

    func refreshServices() {
        serviceManager.fetchServices { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let fetchedServices):
                self.services = fetchedServices
                self.listController.updateServices(fetchedServices)
                let hasRunning = fetchedServices.contains { $0.running }
                self.statusItem.button?.image = drawStatusIcon(active: hasRunning)
            case .failure(let error):
                self.listController.showError(error.localizedDescription)
            }
        }
    }

    private func toggleService(_ name: String, shouldStart: Bool) {
        listController.setServiceLoading(name, isLoading: true)

        let completion: (Result<Void, Error>) -> Void = { [weak self] result in
            if case .failure(let error) = result {
                self?.listController.showServiceError(name, message: error.localizedDescription)
            }
            self?.refreshServices()
        }

        if shouldStart {
            serviceManager.startService(name, completion: completion)
        } else {
            serviceManager.stopService(name, completion: completion)
        }
    }
}
