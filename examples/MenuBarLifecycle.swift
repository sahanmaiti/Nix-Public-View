import AppKit
import SwiftUI

/// Illustrative menu-bar lifecycle. This is not production source.
///
/// Nix has no Dock icon during normal use. Settings, onboarding, and the
/// paywall are real AppKit windows. While one of those windows is open the
/// app becomes a regular application so it can be key and appear in the
/// window menu. When the last window closes, it returns to accessory so the
/// Dock icon goes away with it.

@main
struct MenuBarLifecycleExample: App {
    @NSApplicationDelegateAdaptor(MenuBarDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Nix", systemImage: "xmark.circle") {
            Button("Settings…") {
                appDelegate.showSettings()
            }
        }
        .menuBarExtraStyle(.window)
    }
}

final class MenuBarDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    private var closeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func showSettings() {
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: Text("Settings"))
        window.center()

        closeObserver.map { NotificationCenter.default.removeObserver($0) }
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.settingsWindow = nil
            self?.closeObserver = nil
            NSApp.setActivationPolicy(.accessory)
        }

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }
}
