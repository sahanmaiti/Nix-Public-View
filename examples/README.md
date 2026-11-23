# Examples

These Swift files are short illustrations of patterns Nix actually uses. They are not excerpts of the shipping implementation, and they are not a buildable application.

They exist so a reader can see the platform APIs and the boundaries of the design without the production monitor, rule persistence, licensing, or update integration.

| File | What it shows |
|---|---|
| `MenuBarLifecycle.swift` | A Dock-less menu bar app that becomes a normal app only while a window is open |
| `AccessibilityPermission.swift` | Why Accessibility permission has to be polled, and how an `AXObserver` callback returns to the main actor |
| `LaunchAtLogin.swift` | `SMAppService` registration, including the case where System Settings disagrees with the in-app toggle |
| `QuitBehavior.swift` | The four last-window behaviors, and a cooperative `terminate()` rather than a forced kill |

The following production areas are documented in [the architecture notes](../docs/ARCHITECTURE.md) and are not reproduced here:

- Window confirmation across Spaces, fullscreen, and apps that hide on close
- Per-app rule persistence
- Trial state, license activation, and Keychain storage
- Sparkle update wiring and appcast signing
- The debug verification suite

Do not add those implementations to this folder.
