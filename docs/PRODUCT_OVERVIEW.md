# Product Overview

Nix is a commercial menu bar utility for macOS. Its job is one sentence: when the last window of an application closes, quit that application.

The shipping product is version 1.0.4. It requires macOS 14.6 or later and is distributed as a notarized disk image from [nix-mu.vercel.app](https://nix-mu.vercel.app), not through the Mac App Store.

## The problem

Closing a window on macOS does not quit the application. Safari, Notes, Preview, and most other apps keep a process alive with no windows. That is intentional. Apple expects apps to stay warm so the next launch feels instant. It is the right behavior for Music, Messages, and anything the user wants resident.

It is a poor default for everything else. People who learned Windows read the close button as "I am done." People who understand the Mac model still spend time issuing Command-Q, or they accumulate hidden processes. Nix is the missing preference: persist the apps that should persist, and quit the ones the user has finished with.

## What Nix does

Nix watches regular, Dock-visible applications. When it is confident the last real window has closed, it applies that app's rule:

| Behavior | Result |
|---|---|
| Quit | `NSRunningApplication.terminate()`, the same class of request as Command-Q |
| Hide | The app stays running and is hidden |
| Ignore | macOS behavior is left unchanged |
| Prompt | An alert asks whether to quit |

A global grace period from 0 to 30 seconds sits in front of Quit. Zero means immediate. Any longer delay is visible in the menu bar as a countdown. Reopening a window, activating the app, or unhiding it cancels the quit. An app the user has hidden with Command-H is not quit.

Finder, Dock, SystemUIServer, and Notification Center are permanently excluded. Menu bar agents and other background processes are never tracked, because Nix only follows applications whose activation policy is `.regular`.

## Who it is for

Nix is a paid utility for people who want the Mac to reclaim apps they are finished with, without a window manager and without a script that kills processes. The commercial terms are a 7-day trial and a one-time purchase of $9.99. There is no account and no subscription. Purchase and license delivery go through Lemon Squeezy. When the trial ends and no license is stored, Nix stops quitting applications.

## What the user sees

Nix lives in the menu bar. The status item is an SF Symbol: an xmark while monitoring, a pause symbol while paused, and a slash symbol while monitoring is off. The popover carries the Nix logo, a master switch, the apps currently being watched, and a "Quitting soon" section with a live countdown. Hidden apps are marked differently from visible ones. The list shows five apps and then a count of the rest.

From the popover the user can pause for 30 minutes or 2 hours, resume, check for updates, open Settings, or quit Nix.

Settings is a sidebar window with three pages:

- **General.** Master switch, default behavior, grace period, launch at login, quit notifications, and trial or license status.
- **Apps.** The apps Nix is watching, with search and an immediate per-app behavior override.
- **Whitelist.** The system-protected apps, plus a user list. An app can be added from the ones currently running, or by choosing an application bundle.

First launch is a four-step onboarding window: what Nix is, how it behaves, the Accessibility permission, and an initial choice of default behavior plus launch at login. The onboarding behavior control offers Quit, Hide, and Ask. Ignore remains available later in Settings.

## Permissions and privacy

Nix needs Accessibility permission. That permission is what lets a process observe window lifecycle events in other applications. Nix uses it to learn that windows exist and that they were created, closed, or destroyed. It does not read document text or form values, and it does not record the screen. It does not ask for Screen Recording.

Rules and preferences stay in the app's preferences. License and trial state stay in the Keychain. The only network use is license activation or validation, and update checks. Nix does not send a usage or window payload.

## Distribution

The app is signed with a Developer ID, hardened runtime is on, and the App Sandbox is off. The sandbox has to be off: the Accessibility API this product depends on is not available to a sandboxed Mac App Store process. That constraint is shared by other utilities in this category, and it is why Nix ships as a direct download from [nix-mu.vercel.app](https://nix-mu.vercel.app).

Updates are delivered by Sparkle 2.9.3 from a signed appcast. Signing keys for that feed are not part of this repository.

## What this repository is

This repository is a public engineering view of the product. It describes the architecture and the decisions, and it includes a few isolated illustrations. It is not the application, and it is not a license to build or ship Nix. The proprietary notice is in [`LICENSE`](../LICENSE).
