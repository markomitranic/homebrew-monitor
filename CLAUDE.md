# Homebrew Monitor

macOS menu bar app for monitoring and toggling Homebrew services.

## Build Commands

```bash
make          # Build to build/HomebrewMonitor.app
make run      # Build and open
make clean    # Remove build directory
make install  # Copy to /Applications/
```

## Architecture

- Pure AppKit, no SwiftUI, no Xcode project
- Compiled with `swiftc` via Makefile targeting `arm64-apple-macosx26.0`
- Runs as LSUIElement (no Dock icon, menu bar only)
- Left-click opens popover with service list, right-click shows context menu
- Uses `brew services info --all --json` for service data
- Hardcodes brew path (`/opt/homebrew/bin/brew` with `/usr/local/bin/brew` fallback) since menu bar apps don't inherit shell PATH
- 30-second background timer refreshes badge count

## Key Files

- `Sources/main.swift` — Entry point
- `Sources/AppDelegate.swift` — Status item, popover, click handling, refresh timer
- `Sources/BrewService.swift` — Data model + service manager (shells out to brew)
- `Sources/StatusItemIcon.swift` — Programmatic icon drawing with badge
- `Sources/ServiceListViewController.swift` — Popover content: scrollable service list
- `Sources/ServiceRowView.swift` — Individual service row with green toggle

## Development

Always kill the running app before rebuilding:
```bash
pkill -f HomebrewMonitor; make run
```
