# Inertia

**Smooth, physics-based mouse scrolling for Mac.**

Inertia replaces the stepped, clunky feel of mouse wheel scrolling on macOS with smooth inertial scrolling — giving any mouse the natural momentum feel of a trackpad.

---

## Features (v0.8)

- **Smooth inertial scrolling** — physics-based momentum that coasts naturally after each wheel tick
- **Speed presets** — Slow, Medium, Fast (plus Custom)
- **Smoothness presets** — Low, Regular, High (controls smoothness and momentum duration)
- **Base Speed slider** — always visible, fine-grained control
- **Smoothness slider** — fine-tune momentum duration below presets
- **Modifier hotkeys** — hold a modifier key while scrolling for fast (default: Control, 2x) or slow (default: Option, 0.5x) scrolling, with customizable keys and multipliers
- **Enable/disable toggle** — in both the menubar and settings window
- **Live preview** — test your settings inside the app
- **Custom menubar icon** — template icon adapts to light/dark mode
- **Lightweight menubar app** — no Dock icon, runs silently in the background
- **Credits window** — consolidated attribution for all dependencies
- **Mouse-only** — trackpad behavior is left completely untouched
- **Works everywhere** — consistent scroll feel across all apps including Terminal

## Planned for v1.0

- Visual draggable curve editor
- Per-app scroll profiles
- Import/export settings

---

## Requirements

- macOS Sequoia (15.0) or later
- A USB or Bluetooth mouse with a scroll wheel
- Accessibility permission (required for scroll event interception)

---

## Installation

> Coming soon — v0.8 in development.

Build from source:
1. Clone this repo
2. Open `Inertia.xcodeproj` in Xcode
3. Build and run (Cmd+R)
4. Grant Accessibility permission when prompted

---

## Based On

Inertia's scroll physics are adapted from [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix) by Noah Nuebling. Inertia is a derivative work with substantial changes: completely rewritten engine in pure Swift, new SwiftUI interface, stripped to smooth scrolling only, and released free and open source. Full attribution is maintained in the app's Credits window.

App icon created by [Freepik — Flaticon](https://www.flaticon.com/free-icons/inertia).

---

## License

Open source. Free to use and share.

---

## Contributing

Issues and PRs welcome once v0.8 is stable.
