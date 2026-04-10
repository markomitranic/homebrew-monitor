# Homebrew Monitor

A minimal macOS menu bar app for monitoring and toggling Homebrew services. Inspired by MAMP and similar tools that provide simple control over local services and daemons.

![macOS](https://img.shields.io/badge/macOS-26.0%2B-black)

## Features

- **Menu bar icon** with a badge showing the number of running services
- **Popover service list** — click the icon to see all Homebrew services
- **Green toggle switches** to start/stop services (`brew services start/stop`)
- **Auto-refresh** every 30 seconds to keep the badge count current
- Runs as a menu bar-only app (no Dock icon)

## Build

Requires Swift and targets Apple Silicon (`arm64-apple-macosx26.0`). No Xcode project needed.

```bash
make          # Build to build/HomebrewMonitor.app
make run      # Build and open
make clean    # Remove build directory
make install  # Copy to /Applications/
```

## How It Works

- Left-click the menu bar icon to open the service list
- Right-click for a context menu (Refresh / Quit)
- Toggle any service on or off with the green switch
- Services running as root are shown but cannot be toggled

The app shells out to `brew services info --all --json` for data and `brew services start/stop <name>` for toggling. It looks for the `brew` binary at `/opt/homebrew/bin/brew` (Apple Silicon) with a fallback to `/usr/local/bin/brew` (Intel).

## License

MIT
