import os
import ServiceManagement

/// Illustrative launch-at-login service. This is not production source.
///
/// `SMAppService.mainApp` registers the application itself. Nix does not ship
/// a separate login-item helper. The system status is authoritative: the user
/// can enable or disable the item in System Settings after the in-app toggle
/// was stored, so startup reconciles the stored preference to the system.

enum LaunchAtLogin {
    private static let logger = Logger(subsystem: "com.example.NixIllustration", category: "LaunchAtLogin")

    static var isEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        default:
            return false
        }
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            logger.error("Login item update failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Call once at launch. If registration failed, the caller should write
    /// the system value back into the toggle instead of leaving Settings lying.
    static func reconcile(storedPreference: inout Bool) {
        let actual = isEnabled
        guard storedPreference != actual else { return }
        storedPreference = actual
        logger.info("Launch-at-login preference corrected to the system state")
    }
}
