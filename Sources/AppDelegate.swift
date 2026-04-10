import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let serviceManager = BrewServiceManager()
    private let listController = ServiceListViewController()
    private var services: [BrewServiceInfo] = []
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = drawStatusIcon(runningCount: 0)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }

        popover.contentViewController = listController
        popover.behavior = .transient

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
        }
    }

    private func showContextMenu() {
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
                let runningCount = fetchedServices.filter { $0.running }.count
                self.statusItem.button?.image = drawStatusIcon(runningCount: runningCount)
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
