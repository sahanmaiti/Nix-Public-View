import AppKit
import ApplicationServices

/// Illustrative Accessibility permission handling. This is not production source.
///
/// Granting the permission happens in System Settings. macOS does not deliver
/// a callback to the app when the toggle changes, so Nix reads
/// `AXIsProcessTrusted()` on a short timer and again when the app becomes
/// active. Publishing `isGranted` only when the value changes avoids needless
/// SwiftUI updates.

@MainActor
final class AccessibilityPermission: ObservableObject {
    @Published private(set) var isGranted = false
    private var poll: Timer?

    init() {
        refresh()
        poll = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
            }
        }
    }

    deinit {
        poll?.invalidate()
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        guard trusted != isGranted else { return }
        isGranted = trusted
    }

    /// Shows the system prompt and opens the Accessibility privacy pane.
    func request() {
        let options: CFDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true as CFBoolean
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

/// `AXObserver` invokes a C function. That function must not touch main-actor
/// state inline. The hop below is the shape Nix uses. The production monitor's
/// confirmation policy is intentionally not included.
nonisolated func accessibilityEventCallback(
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: CFString,
    _ context: UnsafeMutableRawPointer?
) {
    let name = notification as String
    var pid: pid_t = 0
    guard AXUIElementGetPid(element, &pid) == .success, pid != 0 else { return }
    _ = (observer, context)

    DispatchQueue.main.async {
        MainActor.assumeIsolated {
            _ = (pid, name)
        }
    }
}

/// Attaches an observer's run-loop source so events are delivered.
/// Production registration covers the application element and each window
/// element, and it has to be repeated when new windows appear. That policy
/// is part of the unpublished monitor.
func installObserverRunLoopSource(_ observer: AXObserver) {
    CFRunLoopAddSource(
        CFRunLoopGetMain(),
        AXObserverGetRunLoopSource(observer),
        .defaultMode
    )
}
