# Features

This is the shipping surface of Nix 1.0.4. Items that are only planned are not listed as features.

## Monitoring

- Quits, hides, ignores, or prompts when the last window of a tracked app closes.
- Tracks applications with the regular activation policy. Nix itself, menu bar agents, and background processes are skipped.
- Never touches Finder, the Dock, SystemUIServer, or Notification Center.
- Leaves hidden apps alone. Command-H is treated as an intentional choice.
- Does not treat a minimized window as closed. The window still exists.
- Cancels an in-progress quit when a window reappears, the app is activated, or the app is unhidden.
- Ignores a bare deactivation. Switching Spaces deactivates an app and can make its windows disappear from an Accessibility query. Nix still requires evidence that a window actually closed.
- Confirms an empty Accessibility window count against the window list before quitting, so a window left open on another Space keeps the app alive. That confirmation does not require Screen Recording permission.
- Uses a second look for apps that intercept the close button and hide, or when the first signal is weak. The timing and classification rules are part of the unpublished monitor.
- Pauses all monitoring for 30 minutes or 2 hours, or until the user resumes.

## Rules

- A global default behavior, stored with the rest of the preferences.
- A per-app override for any app Nix is currently watching. Changes apply immediately.
- A user whitelist, separate from the permanent system exclusions. Whitelisted apps are ignored.
- Whitelist entries can be created from a running app or by selecting an application on disk.
- Search on the Apps page.
- Rules survive relaunch.

The rule model can store a per-app grace period. Settings does not expose that control. The grace period the user can set is global.

## Grace period

- Range is 0 to 30 seconds, in whole seconds. Zero is immediate.
- While a quit is waiting, the menu bar popover lists the app under "Quitting soon" with the remaining time.
- Hiding the app during the wait removes it from that list. Nix does not quit it.
- If `terminate()` returns false, Nix does not escalate. A refusal usually means unsaved changes, and the app keeps its own dialog.

## Menu bar

- Status symbol reflects active, paused, and disabled.
- Popover header shows the Nix logo, a one-line status, and the master switch. The switch is disabled while paused.
- Watched-app list, capped at five rows, with a count of any further apps.
- A status dot distinguishes a visible app from a hidden one.
- Accessibility warning, with a button that opens the permission prompt, when permission is missing.
- Check for Updates, Settings, and Quit Nix.
- Footer shows the marketing version.

## Settings

- Sidebar navigation: General, Apps, Whitelist. Implemented with `NavigationSplitView`, not a tab bar.
- General groups license status, behavior, timing, and system integration.
- Launch at login is a toggle. If registration fails, the toggle is put back to the real system state.
- Optional notification when Nix has quit an app. The notification is posted only after the system reports that the process actually terminated, and only for a quit Nix itself started.

## Onboarding and licensing

- Shown once, on first launch.
- Four steps: welcome, how it works, Accessibility permission, initial setup.
- Setup writes the default behavior and the login-item choice.
- 7-day full-function trial from first launch.
- After expiry, monitoring stays off until a license is activated.
- The user can enter a license key, or open an activation link the store sends.
- Settings shows the trial state and a purchase button while the app is unlicensed. The price shown in the product is $9.99. Purchase is on [nix-mu.vercel.app](https://nix-mu.vercel.app).

## Updates and session behavior

- Sparkle checks for updates from the menu bar. The updater starts automatically in release builds.
- Debug builds do not start the updater. They run an internal verification pass after launch instead.
- No Dock icon while Nix is idle. Opening Settings, onboarding, or the paywall switches the activation policy so the window can be key, then returns Nix to a menu bar app when that window closes.

## Known limitations

These are properties of the shipping app, not a backlog.

- Some applications hide when their close button is clicked. Nix is written to leave those apps running rather than treat a hide as a quit. Behavior still varies, especially in Electron apps whose accessibility trees do not match AppKit.
- A very small window on another Space can be invisible to a process that does not have Screen Recording, because macOS omits its title. Nix does not request that permission. A window in that situation may fail to keep the app alive.
- Some apps leave window-server records behind after the window is gone. Nix tries to ignore records that belong to no Space. If that lookup is unavailable, a leftover record can keep the app alive.
- Per-app grace periods are not editable in Settings.
- Nix cannot ship in the Mac App Store while it depends on an unsandboxed Accessibility client.
