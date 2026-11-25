# Technical Decisions

Each decision below is one the shipping app actually makes. Alternatives are included only where the choice was real.

## Event-driven accessibility, not a poll of the window list

**Decision.** One `AXObserver` per tracked application. Window state is reconsidered when accessibility events arrive, and when workspace hide, unhide, activate, and deactivate notifications arrive.

**Why.** A quit utility that polls every running app spends CPU to rediscover a fact the system will already deliver. Idle cost matters for something that launches at login and sits in the menu bar. Events also carry a reason. A close notification and a deactivation are different facts, and Nix has to treat them differently. A poll only has a count.

**Cost.** Observers have to be created, registered, retried when an app has no windows yet, and torn down on termination. The callback is a C function pointer, so it is the one edge that is not written as ordinary SwiftUI state.

The permission bit is the exception that is polled. macOS does not notify the process when the user flips Accessibility in System Settings.

## Confirm before quitting

**Decision.** The monitor does not call the engine just because an accessibility window count is zero.

**Why.** That count is wrong often enough to ship bugs users feel immediately:

- Switching Spaces deactivates the front app, and windows on the Space you left are not reported the same way.
- Closing a fullscreen window must not quit an app that still has a window on another Space.
- Several popular apps hide on close. The window is gone because the app decided to stay resident.
- Closing a window can leave a window-server record behind, sometimes still titled and full sized.

**How, at the level this repository will describe.** Nix requires a recent close or destroy notification before a deactivation is allowed to matter. It checks the system window list, without Screen Recording, before accepting that no window remains. It asks the window server whether a record belongs to any Space, and it ignores a record that belongs to none. If that lookup cannot be made, it falls back to coarser structural checks. The thresholds, the timing, and the lookup itself are not published.

**Alternative that was rejected.** Request Screen Recording so every window title is populated. That permission is a screen-capture grant. Nix does not capture pixels, and asking users for it would be the wrong trade for a quit utility.

## `terminate()`, never `forceTerminate()`

**Decision.** A quit is `NSRunningApplication.terminate()`. If it returns false, Nix logs the refusal and stops.

**Why.** The product promise is "as if you pressed Command-Q." The target application must run its termination path: save prompts, cleanup, and the chance to refuse. Killing the process would violate that and would lose user data. A notification is posted only after `NSWorkspace` confirms a termination that Nix initiated, so a refused quit does not announce success, and a quit the user performed themselves is not claimed by Nix.

## SwiftUI for interface, AppKit for process and windows

**Decision.** `MenuBarExtra` with the window style is the popover. Settings, onboarding, and the paywall are `NSWindow`s whose content view is an `NSHostingView`. `AppDelegate` is an `NSApplicationDelegateAdaptor`.

**Why.** The popover is a SwiftUI scene and should stay one. The other windows need titlebar behavior, a transparent onboarding background, close cleanup, and control of `NSApp`'s activation policy. SwiftUI's window scenes would fight the "no Dock icon" requirement. The delegate sets `.accessory` at launch, switches to `.regular` while a window is on screen, and returns to `.accessory` when it closes.

**Also rejected.** Electron, or a third-party UI kit. The product is a small system utility. A browser runtime would dominate its memory footprint and its distribution story.

## One environment object, children forwarded

**Decision.** `AppEnvironment` is a singleton `ObservableObject` injected as an `EnvironmentObject`. Child services that publish changes are not all individually injected. Their `objectWillChange` is forwarded.

**Why.** The view tree needs one place to read "are we paused, what is tracked, what is about to quit, is Accessibility granted." Constructing that graph in the environment's initializer makes the wiring obvious and keeps it off the views. Forwarding is the minimum glue that makes a child mutation redraw a parent observer.

**Tradeoff.** A singleton is harder to substitute in tests than a passed-in graph. Nix accepts that and, in debug builds, runs an in-process verification pass against the live services instead of a separate test host. That is appropriate for a single-process utility. It would be the wrong choice for a larger app.

## Main actor by default

**Decision.** `SWIFT_DEFAULT_ACTOR_ISOLATION` is `MainActor`. Published model types are explicitly main-actor isolated as well.

**Why.** AppKit, Accessibility observer delivery, and SwiftUI in this app all converge on the main thread. Default isolation makes the illegal hops visible at the C callback boundary, which is the one that needs a manual hop. It avoids a scatter of annotations that would drift.

## Preferences in UserDefaults, secrets in the Keychain

**Decision.** Behavior, grace period, whitelist, and the other toggles are `@AppStorage` or JSON-encoded `Codable` in `UserDefaults`. The license and the trial clock are in the Keychain.

**Why.** Rules are user preferences. They should be inspectable, low-ceremony, and local. The trial clock should not restart because someone deleted the preferences plist, which is the first thing a casual reset tries. The Keychain is the right local store for that and for a license key. This repository does not include the item layout or the activation flow.

The rule type can represent a per-app grace period, using the global value when an app has no override. Settings only edits the global value. Shipping the model ahead of the control avoids a migration later. It also means the product must not claim per-app grace as a feature. It doesn't.

## System login item, no helper

**Decision.** `SMAppService.mainApp`. On launch, if the stored toggle disagrees with `SMAppService` status, the system wins and the toggle is corrected. A failed register or unregister writes the toggle back to the actual status. `.requiresApproval` is treated as enabled, because the user has asked and macOS is waiting on its own confirmation UI.

**Why.** A modern login item does not need the old helper-app bundle. The interesting bug is drift: System Settings can change the item without the app's toggle noticing. Reconciling at startup is the whole fix.

## Direct distribution, sandbox off, hardened runtime on

**Decision.** Bundle id `com.sahan.Nix`. Deployment target macOS 14.6. App Sandbox disabled. Hardened runtime enabled. Sparkle 2.9.3 for updates. Notarized Developer ID disk image, published at [nix-mu.vercel.app](https://nix-mu.vercel.app).

**Why.** `AXUIElement` observation of other processes is incompatible with the Mac App Store sandbox. Hardened runtime stays on because notarization expects it and because turning it off is not required for Accessibility. Sparkle is the usual update channel for a Developer ID app, and it is the only third-party package.

**What this repository omits.** The Apple team identifier, the Sparkle public key, appcast signatures, export options, and any notarization credentials. Those are operational, not instructional.

## License gate in release only

**Decision.** In release, the engine is enabled only when the user has monitoring turned on and the app is either inside the trial or licensed. In debug, the license gate is not applied, and Sparkle is not started.

**Why.** Development has to be possible without a production license and without update checks against the live appcast. Customers do not get that build. The trial length in the product is seven days.

## Logging

**Decision.** `os.Logger` with a subsystem per area. App names are logged as public privacy so Console shows them. There is no analytics SDK and no crash uploader.

**Why.** A utility like this fails in other companies' apps. The useful field report is a Console filter, not a third-party telemetry pipeline. Public app names are a deliberate privacy annotation: the name is not user content, and redacting it makes the logs useless.

## Native materials where a window is not a standard panel

**Decision.** Onboarding uses a borderless-looking transparent window and an `NSVisualEffectView` bridge, with content inset below the traffic lights.

**Why.** The first-run window should feel like a Mac panel, not a web modal. SwiftUI materials get most of the way there. The traffic-light overlap is an AppKit layout fact of `fullSizeContentView`, so the inset lives in the view rather than in a magic window frame.
