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

Most smooth scrolling apps either charge you upfront, lock features behind a paywall, or bundle in a bunch of stuff you don't need. Inertia gives you more for free than any competitor charges for.

| | **Inertia** | Mac Mouse Fix | Mos | SmoothScroll | Smooze Pro |
|---|---|---|---|---|---|
| **Price** | **Free** | $2.99 | Free | $10/year | $19.99 |
| **Open source** | **Yes** | Yes | Yes (NC) | No | No |
| **Native Swift/SwiftUI** | **Yes** | Obj-C | Obj-C | No | No |
| **Smooth scrolling** | **Yes** | Yes | Yes | Yes | Yes |
| **Speed presets** | **Yes** | 3 presets | No | No | No |
| **Custom speed slider** | **Pro** | No | Yes | Yes | Limited |
| **Smoothness control** | **Presets (free) + slider (Pro)** | 3 presets | Duration slider | No | No |
| **Scroll distance control** | **Presets (free) + slider (Pro)** | No | Step size | Sensitivity | Line count |
| **Modifier hotkeys** | **Pro** | Mouse button only | No | No | No |
| **Per-app scroll profiles** | **Yes** | No | Yes | No | Yes |
| **Per-app blacklist** | **Yes** | No | Yes | No | Yes |
| **Reverse scroll direction** | **Per-axis** | Yes | Yes | No | Yes |
| **Horizontal scrolling** | **Yes** | Yes | Yes | No | Yes |
| **Scroll acceleration toggle** | **Yes** | No | No | No | Yes |
| **Global toggle hotkey** | **Yes** | No | No | No | No |
| **Live preview** | **Yes** | No | No | No | No |
| **Lightweight** | **~2 MB, menubar** | Full app | Menubar | Menubar | Full app |
| **Button remapping** | No | Yes | Yes | No | Yes |

### What you get for free

Every other app in this space either charges upfront or strips out essential features. With Inertia:

- **Speed, smoothness, and distance presets** — all free. Slow, Medium, Fast. Low, Regular, High. Half, Default, Double, Triple. Pick one and go.
- **Reverse scroll, horizontal scroll, acceleration toggle** — all free.
- **Global toggle hotkey** — free. One keyboard shortcut to enable/disable from anywhere.
- **Custom sliders, modifier hotkeys, per-app profiles, and blacklist** — available with Inertia Pro ($5, optional). Power-user features for fine-tuning and per-app customization.

**Inertia's free version covers what most paid apps charge for.** Pro adds fine-tuning and per-app customization for $5 — no trials, no subscriptions, no nag screens.

---

## Features

### Free
- **Smooth inertial scrolling** — physics-based momentum that coasts naturally after each wheel tick
- **Speed presets** — Slow, Medium, Fast
- **Smoothness presets** — Low, Regular, High
- **Scroll distance presets** — Half, Default, Double, Triple
- **Scroll acceleration toggle** — disable the speed curve for linear, constant-speed scrolling
- **Reverse scroll direction** — independent per-axis toggles for vertical and horizontal
- **Smooth horizontal scrolling** — hold Shift to scroll horizontally with the same smooth momentum
- **Global toggle hotkey** — customizable keyboard shortcut to enable/disable Inertia from anywhere
- **Live preview** — test your settings inside the app before using them system-wide
- **Launch at login** — optionally start Inertia automatically on boot
- **Lightweight** — menubar-only, no Dock icon, runs silently in the background
- **Mouse-only** — trackpad scrolling is left completely untouched
- **Works everywhere** — consistent scroll feel across all apps including Terminal

### Inertia Pro ($5, optional)
- **Custom sliders** — fine-tune your exact speed, smoothness, and scroll distance beyond presets
- **Modifier hotkeys** — hold Control to scroll faster, Option to scroll slower, with customizable keys and multipliers
- **Per-app scroll profiles** — override speed, smoothness, distance, and modifier settings for specific apps
- **Per-app blacklist** — disable smooth scrolling entirely for specific apps

Power-user features for fine-tuning and per-app customization. The free version is fully functional without them.

---

## Lives in Your Menu Bar

Inertia runs as a menu bar app — no Dock icon, no app window cluttering your screen, no splash screen on launch. It starts automatically, sits quietly in the top-right corner of your screen, and just works.

Click the menu bar icon to toggle it on/off, adjust settings, or quit — that's all the UI you ever need to see.

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

## Credits

Inertia's scroll physics are adapted from [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix) by Noah Nuebling. Inertia is a derivative work with substantial changes: completely rewritten engine in pure Swift, new SwiftUI interface, stripped to smooth scrolling only, and released free and open source. Full attribution is maintained in the app's Credits window.

App icon created by [Freepik — Flaticon](https://www.flaticon.com/free-icons/inertia).

---

## License

Inertia License (based on the [MMF License](https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)) — free to use and modify. Derivative works must attribute Inertia and may not be sold unless they represent substantial independent work. See [LICENSE](LICENSE) for details.

---

## Contributing

Issues and PRs welcome.
