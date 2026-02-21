# Project Memory

> Permanent record of architectural decisions, constraints, and context. Do not delete entries — mark them superseded instead.

## Project Identity
- **Name:** Inertia
- **Type:** macOS menubar app
- **Purpose:** Replaces stepped mouse wheel scrolling with smooth, physics-based inertial scrolling
- **Created:** 2026-02-18
- **Author:** Jayke Collier
- **GitHub:** https://github.com/JayKayDude/Inertia
- **License:** Open source, free
- **Target OS:** macOS Sequoia (15.0+)

## Foundation
- Built from scratch in **pure Swift/SwiftUI** — no Obj-C bridging
- Uses MMF's physics formulas as **reference only** (not forked code)
- Speedup curve: `y = a * pow(1.1, (x-t) * c) + 1 - a` (b=1.1, p=1.33, t=8)
- Language: Swift 5.9+
- UI: SwiftUI
- Editor: VS Code + Claude Code + Xcode

## Architectural Decisions

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2026-02-18 | Governance docs created at project root | Standard AI governance initialization | Active |
| 2026-02-18 | Menubar-only app, no Dock icon | Lightweight background utility pattern | Active |
| 2026-02-18 | Intercept mouse wheel events only, leave trackpads alone | Trackpads already have system-level inertia | Active |
| 2026-02-19 | **Build from scratch, not fork MMF** | MMF is Obj-C with deep dependencies; clean Swift rewrite is simpler | Active |
| 2026-02-19 | **v0.8/v1.0 versioning** | v0.8 = working app, v1.0 = curve editor + per-app profiles | Active |
| 2026-02-19 | **Smoothness presets: Low/Regular/High** | ~~Off/Low/Regular/High~~ — Off removed since smooth scrolling is the app's purpose | Active |
| 2026-02-19 | Base Speed slider always visible, Advanced expandable | Most users only need one slider | Active |
| 2026-02-19 | Preset ↔ slider sync with "Custom" label | Selecting preset moves slider; dragging away shows Custom | Active |
| 2026-02-20 | **MMF event construction**: CGEvent(source: nil), field 55=22, three delta fields | Terminal and other apps read different delta fields; must set all three consistently | Active |
| 2026-02-20 | **Direction-only rawDelta** | MMF ignores rawDelta magnitude, only uses sign; prevents per-app scroll speed inconsistency | Active |
| 2026-02-20 | **Half-life friction model** | `friction = pow(0.5, 1/halfLifeFrames)` — approximates MMF's drag curve | Active |
| 2026-02-20 | **NSLock for thread safety** | DispatchQueue.sync caused deadlocks (CGEvent.post dispatches to main thread) | Active |
| 2026-02-20 | **Custom Binding for enable toggle** | @AppStorage on ObservableObject doesn't trigger onChange; custom Binding calls start/stop directly | Active |
| 2026-02-20 | **Credits window (not inline footer)** | Consolidates all attribution (MMF, Freepik icon) into dedicated window accessible from menubar | Active |
| 2026-02-20 | **Custom menubar icon (template)** | B&W icon with `template-rendering-intent` so macOS adapts it to light/dark mode | Active |
| 2026-02-20 | **App icon from Freepik/Flaticon** | Colored triskelion icon, resized via sips to all 10 required macOS sizes | Active |
| 2026-02-20 | **Removed minTickSize** | Was in config/UI but never used by engine; dead code removed | Active |
| 2026-02-20 | **Tick rate smoothing (rolling avg of 3)** | Matches MMF's RollingAverage(capacity: 3) for stable speed curve input | Active |
| 2026-02-20 | **velocityThreshold = 120** | Stops animation when <1 px/frame; old value (3.0) ran animation far too long | Active |

## Versioning

### v0.8 — Working App (implemented)
- Scroll engine (CGEventTap + DispatchSourceTimer + MMF physics)
- Menubar with enable toggle
- Settings window with presets, sliders, live preview
- Accessibility permission prompt
- Thread-safe animation with NSLock

### v1.0 — Full Release
- Visual draggable curve editor (Bezier control points)
- Per-app scroll profiles
- Import/export settings
- ~~App icon~~ (done), signed distribution, Homebrew tap

## Scroll Engine Technical Details

### Event Construction (matches MMF)
- `CGEvent(source: nil)` — NOT `CGEventCreateScrollWheelEvent`
- Field 55 = 22 (event subtype)
- `scrollWheelEventIsContinuous` = 1
- `DeltaAxis1` = signedCeil(pixels / 10) — integer line delta
- `PointDeltaAxis1` = integer pixel delta
- `FixedPtDeltaAxis1` = (pixels / 10) * 65536 — 16.16 fixed-point LINE delta

### Key Constants
- `pixelsPerTick` = 45.0
- `pixelsPerLine` = 10.0
- `frameInterval` = 1/120
- `velocityThreshold` = 120.0

### Speed Curve
```
b = 1.1, c = curveExponent, t = 8.0, p = 1.33
a = (p - 1) / (b^c - 1)
multiplier = a * pow(b, (x - t) * c) + 1 - a
clamped to [1.0, 3.0]
```

## Constraints
- iCloud Drive sync — avoid large binary files or rapid file churn
- macOS-only (Darwin 25.3.0 dev environment)
- CGEventTap requires Accessibility permission from user on first launch
- Git repo root is inside Inertia folder (not home directory)

## Phase History
| Phase | Description | Completed |
|-------|-------------|-----------|
| Init  | Governance scaffolding, GitHub repo, project docs | 2026-02-18 |
| 0     | Documentation update for finalized plan | 2026-02-19 |
| 1     | Project setup & menubar shell | 2026-02-19 |
| 2     | Scroll engine core | 2026-02-19 |
| 3     | Configuration & presets | 2026-02-19 |
| 4     | Settings window | 2026-02-19 |
| 5     | Live preview panel | 2026-02-19 |
| —     | Scroll feel tuning & bug fixes | 2026-02-20 |
| 6     | Credits window & custom icons | 2026-02-20 |

## Key File Locations
| File | Purpose |
|------|---------|
| `Inertia/InertiaApp.swift` | App entry, MenuBarExtra, enable toggle, settings/credits windows |
| `Inertia/ScrollEngine.swift` | CGEventTap, velocity, momentum, event posting |
| `Inertia/ScrollConfig.swift` | Parameters, presets, @AppStorage |
| `Inertia/AccessibilityManager.swift` | Permission check & prompt |
| `Inertia/SettingsView.swift` | Main settings window |
| `Inertia/LivePreviewView.swift` | Scrollable preview panel |
| `Inertia/CreditsView.swift` | Credits window (MMF, Freepik attribution) |
| `CLAUDE.md` | Standing instructions for Claude Code |
| `SESSION-STATE.md` | Per-session progress tracker |
| `PROJECT-MEMORY.md` | This file — decisions and context |
| `LEARNING-LOG.md` | Recurring problems and solutions |
| `README.md` | Public-facing project description |
| `ROADMAP.md` | Detailed development roadmap |
