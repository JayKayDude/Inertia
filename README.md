# Inertia

**Smooth, physics-based mouse scrolling for Mac.**

Inertia replaces the stepped, clunky feel of mouse wheel scrolling on macOS with smooth inertial scrolling — giving any mouse the natural momentum feel of a trackpad.

---

## The Problem

macOS treats mouse wheels and trackpads completely differently. Trackpads get beautiful, fluid scrolling with momentum. Mouse wheels get choppy, line-by-line jumps. If you use a mouse, you're stuck with scrolling that feels like it's from 2005.

## The Solution

Inertia intercepts mouse wheel events and replaces them with smooth, physics-based scrolling. Each wheel tick generates momentum that coasts naturally, just like a trackpad. The result is scrolling that feels fluid, responsive, and satisfying.

---

## Why Inertia?

| | Inertia | Mac Mouse Fix | Mos | SmoothScroll |
|---|---|---|---|---|
| **Price** | Free | $2.99 | Free | $5.99 |
| **Open source** | Yes | Yes | Yes | No |
| **Smooth scrolling** | Yes | Yes | Yes | Yes |
| **Native Swift/SwiftUI** | Yes | Obj-C | Obj-C | No |
| **Modifier hotkeys** | Yes (customizable) | Yes | No | No |
| **Lightweight** | ~2 MB, menubar only | Full app | Menubar | Menubar |
| **Focused** | Scrolling only | Buttons, gestures, scrolling | Scrolling + reverse | Scrolling |

**Inertia does one thing and does it well.** No button remapping, no gesture configuration, no feature bloat. Just smooth scrolling with sensible defaults and fine-tuning for those who want it.

---

## Features

- **Smooth inertial scrolling** — physics-based momentum that coasts naturally after each wheel tick
- **Speed presets** — Slow, Medium, Fast (plus Custom with a fine-grained slider)
- **Smoothness presets** — Low, Regular, High (with adjustable momentum duration)
- **Modifier hotkeys** — hold Control to scroll faster (2x) or Option to scroll slower (0.5x), fully customizable
- **Enable/disable toggle** — in both the menubar and settings window
- **Live preview** — test your settings inside the app before using them system-wide
- **Lightweight** — menubar-only app, no Dock icon, runs silently in the background
- **Mouse-only** — trackpad scrolling is left completely untouched
- **Works everywhere** — consistent scroll feel across all apps including Terminal

---

## Lives in Your Menu Bar

Inertia runs as a menu bar app — no Dock icon, no app window cluttering your screen, no splash screen on launch. It starts automatically, sits quietly in the top-right corner of your screen, and just works.

This matters because a scroll utility needs to be always-on and completely out of the way. You shouldn't have to think about it. Click the menu bar icon to toggle it on/off, adjust settings, or quit — that's all the UI you ever need to see.

---

## Screenshots

*Coming soon*

---

## Installation

### Download
Download the latest `.app` from [Releases](https://github.com/JayKayDude/Inertia/releases).

> **Note:** Inertia is not currently signed or notarized. On first launch, right-click the app and select **Open**, then click **Open** in the dialog. This is only needed once. Signed distribution may be added in the future.

### Build from Source
1. Clone this repo
2. Open `Inertia.xcodeproj` in Xcode
3. Build and run (Cmd+R)
4. Grant Accessibility permission when prompted

---

## Requirements

- macOS Sequoia (15.0) or later
- A USB or Bluetooth mouse with a scroll wheel
- Accessibility permission (required for scroll event interception)

---

## How It Works

Inertia creates a low-level event tap (`CGEventTap`) that intercepts mouse wheel events before they reach applications. Each wheel tick is converted into smooth momentum using a physics-based speed curve adapted from [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix). A high-frequency timer (120Hz) applies friction to the velocity each frame, producing natural deceleration.

The engine constructs scroll events that match macOS's native continuous scroll format, so every app — including Terminal — receives consistent, smooth input.

---

## Planned for v2.0

- Per-app blacklist (disable smooth scrolling for specific apps)
- Launch at login
- Horizontal scroll smoothing (Shift+scroll)
- Scroll distance multiplier
- Reverse scroll direction per-axis (independent from trackpad)
- Global keyboard shortcut to toggle Inertia
- Scroll acceleration toggle (disable speed curve for linear scrolling)
- Per-app scroll profiles (different speed/smoothness per app)

---

## Credits

Inertia's scroll physics are adapted from [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix) by Noah Nuebling. Inertia is a derivative work with substantial changes: completely rewritten engine in pure Swift, new SwiftUI interface, stripped to smooth scrolling only, and released free and open source. Full attribution is maintained in the app's Credits window.

App icon created by [Freepik — Flaticon](https://www.flaticon.com/free-icons/inertia).

---

## License

Inertia License (based on the [MMF License](https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)) — free to use and modify. Derivative works must attribute Inertia and may not be sold unless they represent substantial independent work. See [LICENSE](LICENSE) for details.

---

## Contributing

Issues and PRs welcome.
