import AppKit

/// Illustrative last-window policy. This is not production source.
///
/// Nix never force-quits. `NSRunningApplication.terminate()` is the same
/// family of request as Command-Q: the target runs its own termination,
/// including unsaved-changes UI. A `false` result means the app refused.
/// Nix leaves it running in that case.
///
/// A grace period can be cancelled when a window comes back, the app is
/// activated, or it is unhidden. Hidden apps are left alone. The scheduling
/// and cancellation machinery lives in the production decision engine and
/// is not reproduced here.

enum LastWindowBehavior: String, CaseIterable {
    case quit
    case hide
    case ignore
    case prompt

    var title: String {
        switch self {
        case .quit: return "Quit the app"
        case .hide: return "Hide the app"
        case .ignore: return "Do nothing (macOS default)"
        case .prompt: return "Ask me each time"
        }
    }
}

enum QuitAction {
    case terminated
    case refused
    case hidden
    case ignored
}

@MainActor
func applyLastWindowBehavior(
    _ behavior: LastWindowBehavior,
    to app: NSRunningApplication
) -> QuitAction {
    guard !app.isTerminated, !app.isHidden else { return .ignored }

    switch behavior {
    case .quit:
        return app.terminate() ? .terminated : .refused
    case .hide:
        app.hide()
        return .hidden
    case .ignore:
        return .ignored
    case .prompt:
        return prompt(app) ? .terminated : .ignored
    }
}

@MainActor
private func prompt(_ app: NSRunningApplication) -> Bool {
    let name = app.localizedName ?? "This app"
    let alert = NSAlert()
    alert.messageText = "Quit \(name)?"
    alert.informativeText = "\(name) has no open windows."
    alert.addButton(withTitle: "Quit")
    alert.addButton(withTitle: "Keep Running")
    alert.alertStyle = .informational
    guard alert.runModal() == .alertFirstButtonReturn else { return false }
    return app.terminate()
}
