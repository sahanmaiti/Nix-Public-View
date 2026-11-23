# Engineering Challenges

Nix looks small because the successful case is small: the last window closed, so quit. Almost all of the engineering is the unsuccessful case, where macOS or the other application has a different idea of what "closed" means.

The solutions are described here as decisions and failure modes. The production confirmation policy is not included. Publishing it would publish the product.

## A zero window count is not a fact

The Accessibility API will report how many windows an application element currently exposes. That number is a useful hint and a bad trigger.

It drops windows that are on another Space. It drops, or never had, windows in apps whose accessibility tree is incomplete. It also stays non-zero for sheets and leftover elements that are not the user's document window. Nix treats a zero count as something to be confirmed, and it ignores elements that are clearly not primary windows, such as sheets and floating panels.

The confirmation uses the Core Graphics window list for owner, layer, and bounds. Nix does not request Screen Recording. Without that permission, windows on other Spaces come back without titles. The monitor has to decide from structure, not from a title string. Asking for Screen Recording would make the data cleaner and would ask the user for a capability the product does not need.

## Space switches look like quits

Leaving a Space deactivates the current app. If Nix quit on deactivation, changing Spaces would close whatever the user had been using. Deactivation is still useful, because some apps do not deliver a clean close notification. The rule that holds the product together: deactivation may schedule a check, and that check may quit only when there is also recent evidence of a real close or destroy. Evidence expires. An old close must not authorize a later quit.

Fullscreen makes the same bug more specific. Closing the fullscreen window is a real close, and an Accessibility count of zero is then true for the visible Space, while another window is still open elsewhere. The cross-Space check exists for that case.

## Close does not mean close

Discord, Spotify, Slack, and a set of other apps treat the close button as hide. The accessibility tree reports a window going away, and the process is healthy and hidden on purpose. Nix's second confirmation pass exists for weak signals and for this class of app. A hidden application is not a candidate for quit, neither at decision time nor at the end of a grace period.

Electron apps are the long tail. Their accessibility trees vary. Where Nix cannot be sure, the safe product behavior is to leave the app running. The whitelist is the user's override when a particular app is consistently wrong.

## Dead window records keep apps alive

Some applications leave a window-server record after the window is gone. Those records can still look like a normal titled window, which would block a legitimate quit forever.

Nix asks the window server which Space a record belongs to. A record that belongs to no Space is treated as a leftover. This lookup is not public SDK API. If the symbol is missing or the call fails, Nix does not guess with a riskier quit. It falls back to coarser checks, and a leftover can then keep the app alive. That failure mode is preferable to quitting an app the user can still see.

The lookup, the framework, and the fallback thresholds are part of the implementation this repository does not contain.

## Registration is racy

`AXWindowClosed` is delivered on the window element, not on the application. An observer created at launch has to find the windows that already exist, and windows created later have to be registered too. Apps that are running on a background Space when Nix launches may not expose those windows until they are activated. Activation is therefore also a signal to refresh registrations, not only a signal to cancel a pending quit.

If the first registration finds no windows, retrying a few times is more reliable than assuming the app is windowless. The retry schedule is production detail.

## The callback is not Swift

`AXObserverCreate` takes a C function pointer. The monitor is a main-actor class. The callback reads the process identifier and the notification name, then hops to the main queue before it touches the monitor. The context pointer is an unretained reference to the monitor. That is safe only because the monitor removes the observer before the monitor can be released, and because the monitor lives for the process. Getting that lifetime wrong is a crash, not a logic bug.

[`examples/AccessibilityPermission.swift`](../examples/AccessibilityPermission.swift) shows the hop and nothing else.

## Permission has no edge

There is no notification when Accessibility is granted. Nix polls about once a second and also checks when it becomes active. The published flag changes only when the boolean changes. On the rising edge, monitoring is started again for every app already in the tracked list, because those apps were skipped while the process was untrusted.

The prompt API both shows the system dialog and opens the privacy pane. Onboarding explains the permission in the product's words: window lifecycle, not window contents.

## A menu bar app that sometimes has windows

`MenuBarExtra` does not by itself keep Nix out of the Dock. `applicationDidFinishLaunching` sets the accessory activation policy. Settings and onboarding need to be key windows, so those paths temporarily switch to the regular policy and switch back when the window closes. Forgetting the switch-back leaves a Dock icon for a product that promised not to have one. Forgetting the switch-forward makes a window that cannot become key.

The popover itself stays a SwiftUI scene. Mixing the two, instead of rebuilding the popover in AppKit, is what keeps the menu bar UI ordinary SwiftUI.

## The login item lies if you trust your own toggle

`SMAppService` can be changed in System Settings. The boolean in `UserDefaults` will not hear about it. Nix treats the system status as the source of truth at launch and overwrites the stored toggle. It does the same if `register()` or `unregister()` throws, so the switch cannot sit in a state the system rejected.

## Success has to be observed twice

`terminate()` returning true means the request was delivered, not that the process has ended. Nix records the name and waits for `NSWorkspace.didTerminateApplicationNotification`. The notification banner uses that confirmation. A quit the user performed without Nix never enters the pending set, so Nix stays quiet. A grace-period timer that fires after the user has hidden the app, or after the app has quit on its own, checks those conditions again and does nothing.

## Distribution is a product constraint

The feature requires an unsandboxed Accessibility client. That decision removes the Mac App Store and adds Developer ID signing, notarization, and a Sparkle feed. Hardened runtime stays enabled. None of the signing material belongs in a public engineering repo, so this repository stops at the constraint and the framework choice.

## What I would walk a recruiter through

The interesting review is not the SwiftUI. It is the false-positive budget. Every quit Nix gets wrong is a user's app disappearing. The design is therefore biased toward missing a quit: hidden apps survive, refused terminations survive, uncertain cross-Space windows survive, and a failed private lookup survives. The grace period and the popover countdown exist so the successful case is visible and reversible for a few seconds. That is the product.
