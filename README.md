# Inertia

![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-open%20source-green)
![Price](https://img.shields.io/badge/price-free-brightgreen)

**Smooth, physics-based mouse scrolling for Mac.**

Inertia replaces the stepped, clunky feel of mouse wheel scrolling on macOS with smooth inertial scrolling — giving any mouse the natural momentum feel of a trackpad.

---

## The Problem

macOS treats mouse wheels and trackpads completely differently. Trackpads get beautiful, fluid scrolling with momentum. Mouse wheels get choppy, line-by-line jumps. If you use a mouse, you're stuck with scrolling that feels like it's from 2005.

## The Solution

Inertia intercepts mouse wheel events and replaces them with smooth, physics-based scrolling. Each wheel tick generates momentum that coasts naturally, just like a trackpad. The result is scrolling that feels fluid, responsive, and satisfying.

---

## Why Inertia?

Inertia is 100% free with no paywalls, no tiers, no locked features. Every feature is included — and several of them are unique to Inertia, not available in any competitor at any price. Donations are coming soon for anyone who wants to support development.

| | **Inertia** | Mac Mouse Fix | Mos | SmoothScroll | Smooze Pro |
|---|---|---|---|---|---|
| **Price** | **Free** | $2.99 | Free | $10/year | $19.99 |
| **Open source** | **Yes** | Yes | Yes (NC) | No | No |
| **Native Swift/SwiftUI** | **Yes** | Obj-C | Swift (AppKit) | No | No |
| **Smooth scrolling** | **Yes** | Yes | Yes | Yes | Yes |
| **Speed presets** | **Yes** | 3 presets | No | No | No |
| **Custom speed slider** | **Yes** | No | Yes | Yes | Limited |
| **Smoothness control** | **Presets + custom slider** | 3 presets | Duration slider | Animation time | Duration slider |
| **Easing curve control** | **5 presets + sliders + visual curve editor** | 3 presets | Step/Gain/Duration sliders | Animation time | 22 styles + acceleration |
| **Scroll distance presets** | **Yes** | No | No | No | No |
| **Scroll distance slider** | **Yes** | No | Step size | Sensitivity | Line count |
| **Modifier hotkeys** | **Yes (2 keys, adjustable multipliers)** | Yes (4 keys, fixed speed) | Yes (speed-up key) | No | Partial |
| **Per-app scroll profiles** | **Yes** | No | Yes | No | Yes |
| **Per-app blacklist** | **Yes** | No | Yes | Yes | Yes |
| **Reverse scroll direction** | **Per-axis** | Single toggle | Per-axis | Single toggle | Per-axis |
| **Horizontal scrolling** | **Yes** | Yes | Yes | Yes | Yes |
| **Vertical scroll toggle** | **Yes** | No | Yes | No | No |
| **Scroll acceleration toggle** | **Yes** | No | No | No | Yes |
| **Global toggle hotkey** | **Yes (unique)** | No | Hold-to-suppress | No | No |
| **Live preview** | **Yes (unique)** | No | Scroll monitor | No | No |
| **Menubar-only (no Dock icon)** | **Yes** | No | Yes | Yes | No |
| **App size** | **~1 MB** | ~20 MB | ~11 MB | ~2 MB | ~10 MB |
| **Runtime overhead** | **Native Swift (minimal)** | Obj-C (low) | Swift (low) | Obj-C (low) | Unknown |
| **No subscription** | **Yes (100% free)** | Yes ($2.99 once) | Yes (free) | No ($10/year) | Yes ($19.99 once) |
| **Trackpad passthrough** | **Yes** | Yes | Yes | No | Partial |
| **No telemetry** | **Yes (open source)** | Yes (open source) | Yes (open source, NC) | No | No |
| **Works in Terminal** | **Yes** | Yes | Partial | Unknown | Unknown |
| **Settings export/import** | **Yes (unique)** | No | No | No | No |
| **Per-app momentum indicator** | **Yes (unique)** | No | No | No | No |
| **Button remapping** | No | Yes | Yes | No | Yes |

### Unique to Inertia

No competitor has these features at any price:

- **Visual curve editor** — draw your own easing curve by placing and dragging control points on the graph, with live preview and undo/redo
- **Custom easing sliders** — fine-tune momentum with Decay and Shape controls for precise curve shaping beyond presets
- **Global toggle hotkey** — one keyboard shortcut to enable/disable Inertia from anywhere. Persistent toggle, not hold-to-suppress
- **Live preview** — test your scroll settings inside the app before using them system-wide
- **Settings export/import** — export all settings to a file and import them on another machine or as a backup
- **Per-app momentum indicator** — visual dot showing which app's scroll profile is actively driving momentum

### Advantages over Mos

- **Works properly in Terminal** — Mos has known scroll issues in Terminal; Inertia works correctly everywhere
- **Scroll acceleration** — Mos has no speed curve; Inertia scales scroll speed with wheel velocity
- **Presets for quick setup** — Mos is sliders-only; Inertia has one-click presets for speed, smoothness, and distance
- **Global toggle hotkey** — Mos only has hold-to-suppress; Inertia has a persistent on/off hotkey
- **Visual curve editor** — Mos has parameter sliders; Inertia lets you draw the easing curve directly with draggable control points
- **Live preview** — test settings in-app before applying system-wide

---

## Features

- **Smooth inertial scrolling** — physics-based momentum that coasts naturally after each wheel tick
- **Easing presets** — Linear, Gradual, Smooth, Snappy, or Custom — choose how momentum decays
- **Custom easing** — fine-tune with Decay and Shape sliders, or draw your own curve with a visual point editor
- **Speed presets** — Slow, Medium, Fast
- **Custom speed slider** — fine-tune your exact scroll speed beyond presets
- **Smoothness presets** — Low, Regular, High
- **Custom smoothness slider** — fine-tune momentum duration beyond presets
- **Scroll distance presets** — Half, Default, Double, Triple
- **Custom scroll distance slider** — fine-tune scroll distance beyond presets
- **Scroll acceleration toggle** — disable the speed curve for linear, constant-speed scrolling
- **Vertical scroll toggle** — enable or disable smooth vertical scrolling independently
- **Reverse scroll direction** — independent per-axis toggles for vertical and horizontal
- **Smooth horizontal scrolling** — hold Shift to scroll horizontally with the same smooth momentum
- **Modifier hotkeys** — hold Control to scroll faster, Option to scroll slower, with customizable keys and multipliers
- **Per-app scroll profiles** — override speed, smoothness, distance, and modifier settings for specific apps
- **Per-app blacklist** — disable smooth scrolling entirely for specific apps
- **Global toggle hotkey** — customizable keyboard shortcut to enable/disable Inertia from anywhere
- **Live preview** — test your settings inside the app before using them system-wide
- **Settings export/import** — export all settings to a file and import them on another machine or as a backup
- **Per-app momentum indicator** — visual dot showing which app profile is actively driving scroll momentum
- **Menubar icon style** — choose between a low-profile template icon or a colorful icon
- **Update checker** — automatically checks GitHub for new versions and notifies you in the menu and About window
- **Animated settings window** — settings window smoothly resizes when switching tabs or expanding sections
- **Launch at login** — optionally start Inertia automatically on boot
- **Lightweight** — menubar-only, no Dock icon, runs silently in the background
- **Mouse-only** — trackpad scrolling is left completely untouched
- **Works everywhere** — consistent scroll feel across all apps including Terminal

---

## Lives in Your Menu Bar

Inertia runs entirely from the menu bar — no Dock icon, no floating windows, no splash screen. It starts on login, sits quietly in the corner, and stays out of your way. Apps like Mac Mouse Fix and Smooze Pro open as full applications with Dock icons and persistent windows. Inertia doesn't — click the menu bar icon to adjust settings or toggle on/off, and that's it.

## Built for Performance

Inertia is written in pure Swift with SwiftUI — the same native technologies Apple uses for its own apps. This matters:

- **~1.6 MB on disk** — competitors range from 2–20 MB
- **Minimal CPU usage** — native Swift compiles to optimized machine code, no runtime interpreter or garbage collector overhead
- **Low memory footprint** — no Electron, no Java, no web views. Just native macOS code running close to the metal
- **120Hz animation loop** — smooth momentum without waking the CPU more than necessary

Mac Mouse Fix is primarily Objective-C, and SmoothScroll's framework is undisclosed. Mos is Swift but uses the older AppKit framework, not SwiftUI. Inertia is the only app in this space built entirely with modern Swift and SwiftUI — Apple's current-generation UI toolkit — giving it the smallest footprint and cleanest architecture.

## Open Source & Transparent

Inertia is fully open source. This matters for a scroll utility because it runs with Accessibility permissions — one of the most powerful entitlements on macOS. With closed-source apps like SmoothScroll and Smooze Pro, you're trusting that a privileged background process isn't doing anything it shouldn't. With Inertia, you can read every line of code yourself.

- **No telemetry, no analytics, no phone-home** — verifiable, not just claimed
- **No obfuscated code** — the scroll engine, event interception, and settings are all readable Swift
- **Community auditable** — anyone can inspect, fork, or contribute
- **Fully open license** — Mos uses a NonCommercial license that restricts how you can use and distribute it. Inertia's license allows free use and modification with attribution.

---

## Screenshots

### Menu Bar
<img src="screenshots/menubar.png" width="300" alt="Inertia menu bar">

### General Settings
<img src="screenshots/general.png" width="500" alt="General settings tab">

### Advanced Settings
<img src="screenshots/advanced.png" width="500" alt="Advanced settings tab">

### Per-App Profiles
<img src="screenshots/profiles.png" width="500" alt="Per-app scroll profiles">

### Live Preview
<img src="screenshots/preview.png" width="500" alt="Live preview tab">

---

## Installation

### Download
Download the latest `.app` from [Releases](https://github.com/JayKayDude/Inertia/releases).

> **Note:** Inertia is not currently signed or notarized. On first launch, right-click the app and select **Open**, then click **Open** in the dialog. If that doesn't work, go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway**. This is only needed once. Signed distribution may be added in the future.

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

## FAQ

**Does it work with my mouse?**
Yes — any USB or Bluetooth mouse with a scroll wheel. Logitech, Razer, SteelSeries, generic mice, etc. If macOS sees it as a mouse (not a trackpad), Inertia will smooth it.

**Does it affect my trackpad?**
No. Inertia only intercepts mouse wheel events. Trackpad scrolling is left completely untouched — your Magic Trackpad or built-in MacBook trackpad will work exactly as before.

**Is it safe? It asks for Accessibility permissions.**
Accessibility permission is required because Inertia intercepts scroll events at the system level (via `CGEventTap`). This is the same permission every scroll utility needs. Since Inertia is open source, you can verify exactly what the code does — there's no telemetry, no analytics, and no network access.

**Can I use it alongside other mouse utilities?**
Generally yes, but avoid running two smooth scrolling apps at the same time (e.g., Inertia + Mos) since they'll both try to intercept the same events. Other utilities like button remappers should work fine.

**How do I disable it for specific apps?**
Use the App Blacklist in the Advanced tab. Add any app where you want normal stepped scrolling — useful for certain games or apps with custom scroll behavior.

**How is Inertia different from Mos?**
Inertia has scroll acceleration (physics-based speed curve), works properly in Terminal, offers one-click presets for speed/smoothness/distance, has a persistent global toggle hotkey (not hold-to-suppress), includes live preview for testing settings in-app, and lets you toggle smooth vertical scrolling independently. Mos has none of these.

---

## Uninstall

1. Quit Inertia from the menu bar (or right-click the menu bar icon and select **Quit Inertia**)
2. Drag `Inertia.app` to the Trash
3. Optionally remove preferences: `defaults delete com.JayKayDude.Inertia`
4. Optionally remove the login item from **System Settings > General > Login Items**

No kernel extensions, no launch daemons, no leftover processes. It's just an app.

---

## Credits

Inertia's scroll physics are adapted from [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix) by Noah Nuebling. Inertia is a derivative work with substantial changes: completely rewritten engine in pure Swift, new SwiftUI interface, stripped to smooth scrolling only, and released free and open source. Full attribution is maintained in the app's About window.

Inspired by [Mos](https://github.com/Caldis/Mos) by Caldis.

App icon created by [Freepik — Flaticon](https://www.flaticon.com/free-icons/inertia).

---

## AI Disclosure

This project was developed with AI assistance (Claude/Claude Code). All code has been reviewed and tested personally by me.

---

## License

Inertia License (based on the [MMF License](https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)) — free to use and modify. Derivative works must attribute Inertia and may not be sold unless they represent substantial independent work. See [LICENSE](LICENSE) for details.

---

## Contributing

Issues and PRs welcome.
